// Edge Function: translate-backfill
// Übersetzt alle bestehenden Inhalte (oder optional gefiltert nach content_type)
// in die angegebenen Zielsprachen. Nutzt intern translate-content.

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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const body = await req.json().catch(() => ({}));
    const target_languages: string[] = body.target_languages ?? ["en"];
    const content_types: string[] = body.content_types ?? SUPPORTED_TYPES;
    const force: boolean = !!body.force;
    const delayMs: number = typeof body.delay_ms === "number" ? body.delay_ms : 400;

    const { data: rows, error } = await admin
      .from("content")
      .select("id, content_type")
      .in("content_type", content_types)
      .order("created_at", { ascending: true });
    if (error) throw error;

    const summary: { content_id: string; ok: boolean; error?: string }[] = [];

    for (const row of rows ?? []) {
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
        const ok = resp.ok;
        if (!ok) {
          const txt = await resp.text();
          summary.push({ content_id: row.id, ok: false, error: `${resp.status}: ${txt}` });
        } else {
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
    return new Response(
      JSON.stringify({
        ok: true,
        total: summary.length,
        success: okCount,
        failed: summary.length - okCount,
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
