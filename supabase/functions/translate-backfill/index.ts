// Edge Function: translate-backfill
// Übersetzt bestehende Inhalte stapelweise. Pro Aufruf werden max. `limit` Inhalte
// verarbeitet, damit die Edge-Function nicht ins Timeout läuft.
// Standardmäßig werden nur Inhalte verarbeitet, denen mindestens eine Übersetzung
// in einer der Zielsprachen fehlt (only_missing=true).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const admin = createClient(SUPABASE_URL, SERVICE_KEY);

const SUPPORTED_TYPES = ["post", "impulse", "verse", "message", "poll", "video"];

// Pro content_type die Mindestanzahl der erwarteten Übersetzungsfelder
const EXPECTED_FIELDS: Record<string, number> = {
  post: 2,
  impulse: 2,
  verse: 2,
  message: 2,
  poll: 1,
  video: 2,
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const body = await req.json().catch(() => ({}));
    const target_languages: string[] = body.target_languages ?? ["en", "es", "ru"];
    const content_types: string[] = body.content_types ?? SUPPORTED_TYPES;
    const force: boolean = !!body.force;
    const delayMs: number = typeof body.delay_ms === "number" ? body.delay_ms : 150;
    const limit: number = Math.min(typeof body.limit === "number" ? body.limit : 5, 20);
    const onlyMissing: boolean = body.only_missing !== false; // default true

    // Kandidaten laden — nur Inhalte mit existierender Quellzeile
    const SOURCE_TABLE: Record<string, string> = {
      post: "posts",
      impulse: "impulses",
      verse: "verse_of_the_day",
      message: "messages",
      poll: "polls",
      video: "videos",
    };

    let candidates: { id: string; content_type: string }[] = [];
    for (const ct of content_types) {
      const tbl = SOURCE_TABLE[ct];
      if (!tbl) continue;
      const { data: srcRows, error: srcErr } = await admin
        .from(tbl)
        .select("content_id")
        .not("content_id", "is", null)
        .order("created_at", { ascending: true });
      if (srcErr) throw srcErr;
      for (const r of srcRows ?? []) {
        if (r.content_id) candidates.push({ id: r.content_id, content_type: ct });
      }
    }

    // Vorab existierende Übersetzungen laden, um zu filtern
    if (onlyMissing && !force && candidates.length > 0) {
      const ids = candidates.map((r) => r.id);
      const { data: existing } = await admin
        .from("content_translations")
        .select("content_id, language")
        .in("content_id", ids)
        .in("language", target_languages);

      const countByContent = new Map<string, Map<string, number>>();
      for (const t of existing ?? []) {
        const m = countByContent.get(t.content_id) ?? new Map();
        m.set(t.language, (m.get(t.language) ?? 0) + 1);
        countByContent.set(t.content_id, m);
      }

      candidates = candidates.filter((r) => {
        const expected = EXPECTED_FIELDS[r.content_type] ?? 1;
        const m = countByContent.get(r.id);
        if (!m) return true; // gar nichts vorhanden
        // fehlt mind. eine Sprache komplett oder hat zu wenig Felder?
        return target_languages.some((lang) => (m.get(lang) ?? 0) < expected);
      });
    }

    const total_remaining = candidates.length;
    const batch = candidates.slice(0, limit);
    const summary: { content_id: string; ok: boolean; error?: string }[] = [];

    for (const row of batch) {
      try {
        const resp = await fetch(`${SUPABASE_URL}/functions/v1/translate-content`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${SERVICE_KEY}`,
          },
          body: JSON.stringify({
            content_id: row.id,
            target_languages,
            force,
          }),
        });
        if (!resp.ok) {
          const txt = await resp.text();
          summary.push({ content_id: row.id, ok: false, error: `${resp.status}: ${txt}` });
        } else {
          await resp.json().catch(() => null);
          summary.push({ content_id: row.id, ok: true });
        }
      } catch (e) {
        summary.push({
          content_id: row.id,
          ok: false,
          error: e instanceof Error ? e.message : String(e),
        });
      }
      if (delayMs > 0) await new Promise((r) => setTimeout(r, delayMs));
    }

    const okCount = summary.filter((s) => s.ok).length;
    const processed = summary.length;
    const remaining = Math.max(total_remaining - processed, 0);

    return new Response(
      JSON.stringify({
        ok: true,
        processed,
        success: okCount,
        failed: processed - okCount,
        remaining,
        has_more: remaining > 0,
        details: summary,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("translate-backfill error:", e);
    return new Response(
      JSON.stringify({ error: e instanceof Error ? e.message : String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
