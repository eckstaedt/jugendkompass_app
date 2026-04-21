// Edge Function: translate-backfill
// Stapelweise Übersetzung. Pro Aufruf max. `limit` Inhalte (default 1).
// Effizient: zählt zuerst die echte Gesamtmenge in der Quelltabelle und ermittelt
// die wirklich noch fehlenden (remaining), damit das UI einen korrekten Fortschritt zeigt.

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

// Maximale Seitenanzahl beim Scannen der Quelltabelle pro Request.
// 5000 Datensätze sind günstig zu paginieren und decken die App locker ab.
const MAX_SCAN = 5000;
const PAGE_SIZE = 500;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const body = await req.json().catch(() => ({}));
    const target_languages: string[] = body.target_languages ?? ["en", "es", "ru", "pl"];
    const content_types: string[] = body.content_types ?? Object.keys(SOURCE_TABLE);
    const force: boolean = !!body.force;
    const delayMs: number = typeof body.delay_ms === "number" ? body.delay_ms : 100;
    const limit: number = Math.min(typeof body.limit === "number" ? body.limit : 1, 20);
    const onlyMissing: boolean = body.only_missing !== false;

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

    // 1) Gesamtanzahl in der Quelltabelle (echte Obergrenze).
    const { count: totalCount } = await admin
      .from(tbl)
      .select("content_id", { count: "exact", head: true })
      .not("content_id", "is", null);

    // 2) Suche fehlende Kandidaten paginiert. Stoppe sobald wir genug für diesen Batch
    //    haben UND mindestens eine grobe Schätzung der Restmenge ermitteln können.
    const missing: string[] = [];
    let scanned = 0;
    let scannedComplete = 0; // bereits vollständig übersetzte content_ids im gescannten Bereich
    let pageStart = 0;
    let exhausted = false;

    while (pageStart < MAX_SCAN) {
      const { data: srcRows, error: srcErr } = await admin
        .from(tbl)
        .select("content_id")
        .not("content_id", "is", null)
        .order("created_at", { ascending: true })
        .range(pageStart, pageStart + PAGE_SIZE - 1);
      if (srcErr) throw srcErr;
      const ids = (srcRows ?? []).map((r: any) => r.content_id as string).filter(Boolean);
      if (ids.length === 0) {
        exhausted = true;
        break;
      }
      scanned += ids.length;

      if (force || !onlyMissing) {
        for (const id of ids) {
          if (missing.length < limit) missing.push(id);
        }
      } else {
        // Aggregiere existierende Übersetzungen für diese Seite.
        const { data: existing } = await admin
          .from("content_translations")
          .select("content_id")
          .in("content_id", ids)
          .in("language", target_languages);
        const counts = new Map<string, number>();
        for (const t of (existing ?? []) as any[]) {
          counts.set(t.content_id, (counts.get(t.content_id) ?? 0) + 1);
        }
        for (const id of ids) {
          const c = counts.get(id) ?? 0;
          if (c >= expectedTotalPerContent) {
            scannedComplete += 1;
          } else {
            missing.push(id);
          }
        }
      }

      if (ids.length < PAGE_SIZE) {
        exhausted = true;
        break;
      }
      pageStart += PAGE_SIZE;

      // Wenn wir genug Batch-Kandidaten haben UND bereits viel gescannt wurde,
      // brechen wir früher ab — die remaining-Schätzung ist dann konservativ.
      if (missing.length >= limit && scanned >= 1000) break;
    }

    // 3) Realistische remaining-Schätzung:
    //    bekannte fehlende (missing.length) + hochgerechnete fehlende im noch nicht gescannten Bereich.
    const total = totalCount ?? scanned;
    const unscanned = Math.max(total - scanned, 0);
    let remainingEstimate: number;
    if (force || !onlyMissing) {
      remainingEstimate = total;
    } else if (exhausted) {
      remainingEstimate = missing.length;
    } else {
      const missRate = scanned > 0 ? missing.length / scanned : 1;
      remainingEstimate = missing.length + Math.round(unscanned * missRate);
    }

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
    const remaining = Math.max(remainingEstimate - processed, 0);
    const has_more = remaining > 0 && (missing.length > processed || !exhausted);

    return new Response(
      JSON.stringify({
        ok: true,
        processed,
        success: okCount,
        failed: processed - okCount,
        remaining,
        total,
        already_complete: scannedComplete,
        scanned,
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
