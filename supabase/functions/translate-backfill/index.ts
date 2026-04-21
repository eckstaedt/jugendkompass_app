// Edge Function: translate-backfill
// Stapelweise Übersetzung. Pro Aufruf max. `limit` Inhalte (default 1).
// Berücksichtigt fehlende Sprachen PRO FELD: ein Inhalt mit nur 1 fehlenden
// Sprache wird genauso erkannt wie einer mit 4 fehlenden Sprachen, aber pro
// Aufruf werden NUR die wirklich fehlenden Sprachen übersetzt.

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

// Erwartete Feldnamen je content_type (müssen zu translate-content passen).
const EXPECTED_FIELD_NAMES: Record<string, string[]> = {
  post: ["title", "body"],
  impulse: ["title", "impulse_text"],
  verse: ["verse", "reference"],
  message: ["title", "message"],
  poll: ["question"],
  video: ["title", "description"],
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

    const expectedFields = EXPECTED_FIELD_NAMES[ct] ?? [];
    const expectedTotalPerContent = expectedFields.length * target_languages.length;

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

    // 2) Vorhandene Übersetzungen EXAKT laden (nur erwartete Felder & Zielsprachen),
    //    damit wir pro Inhalt sehen, welche (lang,field)-Paare fehlen.
    // Map: content_id -> Set("<lang>:<field>")
    const present = new Map<string, Set<string>>();
    if (!force && expectedFields.length > 0) {
      // Supabase gibt standardmäßig max. 1000 Zeilen pro Query zurück.
      // Darum Chunkgröße dynamisch so wählen, dass erwartete Übersetzungszeilen
      // pro Chunk sicher darunter bleiben (z.B. posts: 112 * 8 = 896).
      const CHUNK = Math.max(1, Math.floor(900 / Math.max(expectedTotalPerContent, 1)));
      for (let i = 0; i < allIds.length; i += CHUNK) {
        const chunk = allIds.slice(i, i + CHUNK);
        const { data, error } = await admin
          .from("content_translations")
          .select("content_id, language, field_name")
          .in("content_id", chunk)
          .in("language", target_languages)
          .in("field_name", expectedFields);
        if (error) throw error;
        for (const row of (data ?? []) as any[]) {
          const key = `${row.language}:${row.field_name}`;
          let set = present.get(row.content_id);
          if (!set) {
            set = new Set();
            present.set(row.content_id, set);
          }
          set.add(key);
        }
      }
    }

    // 3) Liste der Inhalte mit irgendeiner fehlenden (lang,field)-Kombination.
    //    Speichere zusätzlich, welche Sprachen pro Inhalt noch nötig sind.
    const missing: { id: string; missingLangs: string[] }[] = [];
    let alreadyComplete = 0;
    for (const id of allIds) {
      const set = present.get(id);
      const have = set ? set.size : 0;
      if (force || have < expectedTotalPerContent) {
        // Bestimme fehlende Sprachen: eine Sprache gilt als "fehlend",
        // wenn nicht alle erwarteten Felder dafür existieren.
        const missingLangs: string[] = [];
        for (const lang of target_languages) {
          let allFieldsPresent = true;
          for (const f of expectedFields) {
            if (!set || !set.has(`${lang}:${f}`)) {
              allFieldsPresent = false;
              break;
            }
          }
          if (force || !allFieldsPresent) missingLangs.push(lang);
        }
        if (missingLangs.length > 0) {
          missing.push({ id, missingLangs });
        } else {
          alreadyComplete += 1;
        }
      } else {
        alreadyComplete += 1;
      }
    }

    const remainingBefore = missing.length;
    const batch = missing.slice(0, limit);
    const summary: {
      content_id: string;
      ok: boolean;
      languages?: string[];
      error?: string;
    }[] = [];

    for (const item of batch) {
      try {
        const resp = await fetch(`${SUPABASE_URL}/functions/v1/translate-content`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${SERVICE_KEY}`,
          },
          body: JSON.stringify({
            content_id: item.id,
            // Nur tatsächlich fehlende Sprachen anfordern → schneller, weniger AI-Calls.
            target_languages: item.missingLangs,
            force,
          }),
        });
        if (!resp.ok) {
          const txt = await resp.text();
          summary.push({
            content_id: item.id,
            ok: false,
            languages: item.missingLangs,
            error: `${resp.status}: ${txt}`,
          });
        } else {
          await resp.json().catch(() => null);
          summary.push({ content_id: item.id, ok: true, languages: item.missingLangs });
        }
      } catch (e) {
        summary.push({
          content_id: item.id,
          ok: false,
          languages: item.missingLangs,
          error: e instanceof Error ? e.message : String(e),
        });
      }
      if (delayMs > 0) await new Promise((r) => setTimeout(r, delayMs));
    }

    const okCount = summary.filter((s) => s.ok).length;
    const processed = summary.length;
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
