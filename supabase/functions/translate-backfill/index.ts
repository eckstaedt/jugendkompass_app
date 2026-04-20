// Edge Function: translate-backfill
// Stapelweise Übersetzung. Pro Aufruf max. `limit` Inhalte (default 5).
// Nutzt nur die Quelltabellen (kein orphan-content), und übergibt Inhalte direkt
// an translate-content. Filterung per `only_missing` über content_translations.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const admin = createClient(SUPABASE_URL, SERVICE_KEY);

const SOURCE_TABLE: Record<string, string> = {
  post: "posts",
  impulse: "impulses",
  verse: "verse_of_the_day",
  message: "messages",
  poll: "polls",
  video: "videos",
};

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
    const content_types: string[] = body.content_types ?? Object.keys(SOURCE_TABLE);
    const force: boolean = !!body.force;
    const delayMs: number = typeof body.delay_ms === "number" ? body.delay_ms : 100;
    const limit: number = Math.min(typeof body.limit === "number" ? body.limit : 5, 20);
    const onlyMissing: boolean = body.only_missing !== false;

    // Filter ein content_type pro Aufruf (Frontend ruft pro Typ separat auf).
    const ct = content_types[0];
    const tbl = SOURCE_TABLE[ct];
    if (!tbl) {
      return new Response(
        JSON.stringify({ error: `unsupported content_type: ${ct}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Lade nur eine begrenzte Auswahl an Kandidaten (oversample für Filter).
    const oversample = onlyMissing && !force ? 200 : limit;
    const { data: srcRows, error: srcErr } = await admin
      .from(tbl)
      .select("content_id")
      .not("content_id", "is", null)
      .order("created_at", { ascending: true })
      .limit(oversample);
    if (srcErr) throw srcErr;

    let candidateIds = (srcRows ?? [])
      .map((r: any) => r.content_id as string)
      .filter(Boolean);

    let totalRemainingEstimate = candidateIds.length;

    if (onlyMissing && !force && candidateIds.length > 0) {
      const { data: existing } = await admin
        .from("content_translations")
        .select("content_id, language")
        .in("content_id", candidateIds)
        .in("language", target_languages);

      const countByContent = new Map<string, Map<string, number>>();
      for (const t of (existing ?? []) as any[]) {
        const m = countByContent.get(t.content_id) ?? new Map();
        m.set(t.language, (m.get(t.language) ?? 0) + 1);
        countByContent.set(t.content_id, m);
      }
      const expected = EXPECTED_FIELDS[ct] ?? 1;
      candidateIds = candidateIds.filter((id) => {
        const m = countByContent.get(id);
        if (!m) return true;
        return target_languages.some((lang) => (m.get(lang) ?? 0) < expected);
      });
      totalRemainingEstimate = candidateIds.length;
    }

    const batch = candidateIds.slice(0, limit);
    const summary: { content_id: string; ok: boolean; error?: string }[] = [];

    for (const id of batch) {
      try {
        const resp = await fetch(`${SUPABASE_URL}/functions/v1/translate-content`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${SERVICE_KEY}`,
          },
          body: JSON.stringify({
            content_id: id,
            target_languages,
            force,
          }),
        });
        if (!resp.ok) {
          const txt = await resp.text();
          summary.push({ content_id: id, ok: false, error: `${resp.status}: ${txt}` });
        } else {
          await resp.json().catch(() => null);
          summary.push({ content_id: id, ok: true });
        }
      } catch (e) {
        summary.push({
          content_id: id,
          ok: false,
          error: e instanceof Error ? e.message : String(e),
        });
      }
      if (delayMs > 0) await new Promise((r) => setTimeout(r, delayMs));
    }

    const okCount = summary.filter((s) => s.ok).length;
    const processed = summary.length;
    const remaining = Math.max(totalRemainingEstimate - processed, 0);

    return new Response(
      JSON.stringify({
        ok: true,
        processed,
        success: okCount,
        failed: processed - okCount,
        remaining,
        has_more: remaining > 0 || (oversample === candidateIds.length + processed),
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
