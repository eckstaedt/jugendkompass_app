// Edge Function: translate-backfill
// Stapelweise Übersetzung. Pro Aufruf max. `limit` Inhalte (default 1).
// remaining ist EXAKT (keine Schätzung): es werden nur Inhalte gezählt,
// die noch nicht in allen Zielsprachen vollständig übersetzt sind.

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

// Anzahl übersetzbarer Felder je content_type (siehe translate-content).
const EXPECTED_FIELDS: Record<string, number> = {
  post: 2,
  impulse: 2,
  verse: 2,
  message: 2,
  poll: 1,
  video: 2,
};

const PAGE_SIZE = 1000;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const body = await req.json().catch(() => ({}));
    const target_languages: string[] = body.target_languages ?? ["en", "es", "ru", "pl"];
    const content_types: string[] = body.content_types ?? Object.keys(SOURCE_TABLE);
    const force: boolean = !!body.force;
    const delayMs: number = typeof body.delay_ms === "number" ? body.delay_ms : 100;
    const limit: number = Math.min(typeof body.limit === "number" ? body.limit : 1, 20);

    const ct = content_types[0];
    const tbl = SOURCE_TABLE[ct];
    if (!tbl) {
      return new Response(
        JSON.stringify({ error: `unsupported content_type: ${ct}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const expected = EXPECTED_FIELDS[ct] ?? 1;
    const expectedTotalPerContent = expected * target_languages.length;

    // 1) ALLE content_ids der Quelltabelle laden (paginiert).
    const allIds: string[] = [];
    let pageStart = 0;
    while (true) {
      const { data, error } = await admin
        .from(tbl)
        .select("content_id")
        .not("content_id", "is", null)
        .order("created_at", { ascending: true })
        .range(pageStart, pageStart + PAGE_SIZE - 1);
      if (error) throw error;
      const ids = (data ?? []).map((r: any) => r.content_id as string).filter(Boolean);
      allIds.push(...ids);
      if (ids.length < PAGE_SIZE) break;
      pageStart += PAGE_SIZE;
    }

    const total = allIds.length;

    // 2) Übersetzungs-Counts EXAKT bestimmen (paginiert über content_translations).
    const counts = new Map<string, number>();
    if (!force) {
      // Lade pro Chunk an content_ids.
      const CHUNK = 200;
      for (let i = 0; i < allIds.length; i += CHUNK) {
        const chunk = allIds.slice(i, i + CHUNK);
        const { data, error } = await admin
          .from("content_translations")
          .select("content_id")
          .in("content_id", chunk)
          .in("language", target_languages);
        if (error) throw error;
        for (const row of (data ?? []) as any[]) {
          counts.set(row.content_id, (counts.get(row.content_id) ?? 0) + 1);
        }
      }
    }

    // 3) Echte Liste der fehlenden Inhalte.
    const missing: string[] = [];
    let alreadyComplete = 0;
    for (const id of allIds) {
      const c = counts.get(id) ?? 0;
      if (force || c < expectedTotalPerContent) {
        missing.push(id);
      } else {
        alreadyComplete += 1;
      }
    }

    const remainingBefore = missing.length;
    const batch = missing.slice(0, limit);
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
    // remaining nach diesem Batch = vorher - erfolgreich übersetzte
    const remaining = Math.max(remainingBefore - okCount, 0);
    const has_more = remaining > 0;

    return new Response(
      JSON.stringify({
        ok: true,
        processed,
        success: okCount,
        failed: processed - okCount,
        remaining,
        total,
        already_complete: alreadyComplete,
        scanned: total,
        has_more,
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
