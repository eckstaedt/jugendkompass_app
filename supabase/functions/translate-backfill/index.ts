// Edge Function: translate-backfill
// Stapelweise Übersetzung. Pro Aufruf max. `limit` Arbeitseinheiten (default 1).
// Eine Arbeitseinheit = ein Inhalt in einer fehlenden Sprache.
// Dadurch sinkt `remaining` auch dann sichtbar, wenn bei einem Beitrag nur eine
// einzelne Sprache/Feld-Kombination fehlt.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { requireAdminOrServiceRole } from "../_shared/auth-guard.ts";

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
  edition: "editions",
};

// Erwartete Feldnamen je content_type (müssen zu translate-content passen).
const EXPECTED_FIELD_NAMES: Record<string, string[]> = {
  post: ["title", "body"],
  impulse: ["title", "impulse_text"],
  verse: ["verse", "reference"],
  message: ["title", "message"],
  poll: ["question"],
  video: ["title", "description"],
  edition: ["title", "body"],
};

const PAGE_SIZE = 1000;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const denied = await requireAdminOrServiceRole(req, corsHeaders);
  if (denied) return denied;

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

    // 1) ALLE content_ids der Quelltabelle laden (paginiert).
    const allIds: string[] = [];
    let pageStart = 0;
    while (true) {
      const { data, error } = await admin
        .from(tbl)
        .select("content_id")
        .not("content_id", "is", null)
        .order("content_id", { ascending: true })
        .range(pageStart, pageStart + PAGE_SIZE - 1);
      if (error) throw error;
      const ids = (data ?? []).map((r: any) => r.content_id as string).filter(Boolean);
      allIds.push(...ids);
      if (ids.length < PAGE_SIZE) break;
      pageStart += PAGE_SIZE;
    }

    const totalContents = allIds.length;
    const total = totalContents * target_languages.length;

    // 2) Vorhandene Übersetzungen EXAKT laden (nur erwartete Felder & Zielsprachen).
    // Supabase gibt standardmäßig max. 1000 Zeilen pro Query zurück. Darum Chunkgröße
    // dynamisch so wählen, dass erwartete Übersetzungszeilen pro Chunk darunter bleiben.
    // Map: content_id -> Set("<lang>:<field>")
    const present = new Map<string, Set<string>>();
    if (!force && expectedFields.length > 0) {
      const expectedRowsPerContent = expectedFields.length * target_languages.length;
      const CHUNK = Math.max(1, Math.floor(900 / Math.max(expectedRowsPerContent, 1)));
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

    // 3) Fehlende Arbeitseinheiten bilden: pro Inhalt und Sprache genau eine Unit,
    // wenn mindestens ein erwartetes Feld in dieser Sprache fehlt.
    const missingUnits: { id: string; language: string }[] = [];
    let alreadyComplete = 0;
    const incompleteContentIds = new Set<string>();

    for (const id of allIds) {
      const set = present.get(id);
      for (const lang of target_languages) {
        let completeForLanguage = !force;
        if (!force) {
          for (const field of expectedFields) {
            if (!set || !set.has(`${lang}:${field}`)) {
              completeForLanguage = false;
              break;
            }
          }
        }

        if (force || !completeForLanguage) {
          missingUnits.push({ id, language: lang });
          incompleteContentIds.add(id);
        } else {
          alreadyComplete += 1;
        }
      }
    }

    const remainingBefore = missingUnits.length;
    const batch = missingUnits.slice(0, limit);
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
            // Nur eine tatsächlich fehlende Sprache pro Arbeitseinheit → schneller,
            // weniger Timeouts und Fortschritt sinkt nach jedem erfolgreichen Schritt.
            target_languages: [item.language],
            force,
          }),
        });
        if (!resp.ok) {
          const txt = await resp.text();
          summary.push({
            content_id: item.id,
            ok: false,
            languages: [item.language],
            error: `${resp.status}: ${txt}`,
          });
        } else {
          await resp.json().catch(() => null);
          summary.push({ content_id: item.id, ok: true, languages: [item.language] });
        }
      } catch (e) {
        summary.push({
          content_id: item.id,
          ok: false,
          languages: [item.language],
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
        total_contents: totalContents,
        incomplete_contents: incompleteContentIds.size,
        already_complete: alreadyComplete,
        scanned: totalContents,
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
