// Edge Function: translate-content
// Übersetzt Felder eines Inhalts via Lovable AI Gateway in eine Zielsprache und
// speichert das Ergebnis in public.content_translations.
// HTML-Tags werden bewahrt (Prompt + leichte Validierung).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY")!;

const admin = createClient(SUPABASE_URL, SERVICE_KEY);

// Welche Felder pro content_type übersetzt werden
const FIELD_MAP: Record<string, { table: string; fields: string[] }> = {
  post:    { table: "posts",            fields: ["title", "body"] },
  impulse: { table: "impulses",         fields: ["title", "impulse_text", "notification_title", "notification_body"] },
  verse:   { table: "verse_of_the_day", fields: ["verse", "reference"] },
  message: { table: "messages",         fields: ["title", "message"] },
  poll:    { table: "polls",            fields: ["question"] },
  video:   { table: "videos",           fields: ["title", "description"] },
  edition: { table: "editions",         fields: ["title", "body", "notification_title", "notification_body"] },
};

const LANG_NAMES: Record<string, string> = {
  en: "English",
  de: "German",
  ru: "Russian",
  es: "Spanish",
  pl: "Polish",
};

async function sha256(text: string): Promise<string> {
  const buf = new TextEncoder().encode(text);
  const hash = await crypto.subtle.digest("SHA-256", buf);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function countTags(html: string): number {
  return (html.match(/<[^>]+>/g) || []).length;
}

async function translateField(
  value: string,
  targetLang: string,
): Promise<string> {
  const langName = LANG_NAMES[targetLang] ?? targetLang;
  const containsHtml = /<[^>]+>/.test(value);

  const systemPrompt = containsHtml
    ? `You are a professional translator. Translate the user's text from German to ${langName}.
CRITICAL RULES:
- Preserve ALL HTML tags, attributes, and whitespace EXACTLY as in the original.
- Translate ONLY the visible text content between tags and inside alt/title attributes.
- Do NOT add, remove, reorder, or rename any tag.
- Return ONLY the translated HTML string, no commentary, no markdown fences.`
    : `You are a professional translator. Translate the user's text from German to ${langName}.
Return ONLY the translated text, no commentary, no quotes.`;

  const body = {
    model: "google/gemini-3-flash-preview",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: value },
    ],
  };

  const resp = await fetch(
    "https://ai.gateway.lovable.dev/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    },
  );

  if (!resp.ok) {
    const txt = await resp.text();
    throw new Error(`AI gateway ${resp.status}: ${txt}`);
  }

  const data = await resp.json();
  let translated: string = data?.choices?.[0]?.message?.content ?? "";
  translated = translated.trim();

  // Sanity-Check: bei HTML soll Tag-Anzahl gleich bleiben — sonst Retry strikt
  if (containsHtml) {
    const before = countTags(value);
    const after = countTags(translated);
    if (before !== after) {
      const retry = await fetch(
        "https://ai.gateway.lovable.dev/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${LOVABLE_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: "google/gemini-3-flash-preview",
            messages: [
              {
                role: "system",
                content:
                  systemPrompt +
                  `\nThe previous output had a different HTML tag count. The original has ${before} tags. Output MUST contain exactly ${before} tags in the same order.`,
              },
              { role: "user", content: value },
            ],
          }),
        },
      );
      if (retry.ok) {
        const retryData = await retry.json();
        const retryText = (retryData?.choices?.[0]?.message?.content ?? "")
          .trim();
        if (countTags(retryText) === before) translated = retryText;
      }
    }
  }

  return translated;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { content_id, target_languages, force } = await req.json();

    if (!content_id || !Array.isArray(target_languages) || target_languages.length === 0) {
      return new Response(
        JSON.stringify({ error: "content_id and target_languages[] required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Inhaltstyp ermitteln
    const { data: contentRow, error: contentErr } = await admin
      .from("content")
      .select("id, content_type")
      .eq("id", content_id)
      .maybeSingle();
    if (contentErr) throw contentErr;
    if (!contentRow) {
      return new Response(JSON.stringify({ error: "content not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const map = FIELD_MAP[contentRow.content_type];
    if (!map) {
      return new Response(
        JSON.stringify({ error: `unsupported content_type: ${contentRow.content_type}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Quellzeile laden
    const { data: source, error: sourceErr } = await admin
      .from(map.table)
      .select(map.fields.join(",") + ",content_id")
      .eq("content_id", content_id)
      .maybeSingle();
    if (sourceErr) throw sourceErr;
    if (!source) {
      return new Response(JSON.stringify({ error: "source row not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Polls: zusätzlich poll_options übersetzen (option:<id>)
    const extraFields: { field_name: string; value: string }[] = [];
    if (contentRow.content_type === "poll") {
      const { data: opts } = await admin
        .from("poll_options")
        .select("id, option_text")
        .eq("poll_id", (source as any).id ?? undefined);
      // option lookup: poll row → use polls.id via secondary fetch
      const { data: pollRow } = await admin
        .from("polls")
        .select("id")
        .eq("content_id", content_id)
        .maybeSingle();
      if (pollRow?.id) {
        const { data: pollOpts } = await admin
          .from("poll_options")
          .select("id, option_text")
          .eq("poll_id", pollRow.id);
        for (const o of pollOpts ?? []) {
          if (o.option_text) {
            extraFields.push({ field_name: `option:${o.id}`, value: o.option_text });
          }
        }
      }
    }

    const results: Record<string, Record<string, string>> = {};

    for (const lang of target_languages as string[]) {
      results[lang] = {};

      // Standardfelder
      for (const f of map.fields) {
        const original: string | null = (source as any)[f];
        if (!original) continue;
        const hash = await sha256(original);

        if (!force) {
          const { data: existing } = await admin
            .from("content_translations")
            .select("id, source_hash, status")
            .eq("content_id", content_id)
            .eq("language", lang)
            .eq("field_name", f)
            .maybeSingle();
          if (existing && existing.source_hash === hash && existing.status !== "outdated") {
            continue;
          }
        }

        const translated = await translateField(original, lang);
        const { error: upErr } = await admin
          .from("content_translations")
          .upsert(
            {
              content_id,
              language: lang,
              field_name: f,
              value: translated,
              source_hash: hash,
              status: "auto",
            },
            { onConflict: "content_id,language,field_name" },
          );
        if (upErr) throw upErr;
        results[lang][f] = translated;
      }

      // Poll-Optionen
      for (const ef of extraFields) {
        const hash = await sha256(ef.value);
        if (!force) {
          const { data: existing } = await admin
            .from("content_translations")
            .select("id, source_hash, status")
            .eq("content_id", content_id)
            .eq("language", lang)
            .eq("field_name", ef.field_name)
            .maybeSingle();
          if (existing && existing.source_hash === hash && existing.status !== "outdated") {
            continue;
          }
        }
        const translated = await translateField(ef.value, lang);
        const { error: upErr } = await admin
          .from("content_translations")
          .upsert(
            {
              content_id,
              language: lang,
              field_name: ef.field_name,
              value: translated,
              source_hash: hash,
              status: "auto",
            },
            { onConflict: "content_id,language,field_name" },
          );
        if (upErr) throw upErr;
        results[lang][ef.field_name] = translated;
      }
    }

    return new Response(
      JSON.stringify({ ok: true, content_id, results }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("translate-content error:", e);
    return new Response(
      JSON.stringify({ error: e instanceof Error ? e.message : String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
