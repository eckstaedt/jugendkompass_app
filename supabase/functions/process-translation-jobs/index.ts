// Translation worker v2 — translates German source content into every active
// target language using Claude (Anthropic API).
//
// Triggered by:
//   • the database (pg_net) immediately after content is created/changed
//   • a pg_cron safety net every 2 minutes
//   • manual invoke (Dashboard / CLI) with {"action": "..."}
//
// Auth: header `x-translation-secret: <vault translation_worker_secret>` or
//       `Authorization: Bearer <SERVICE_ROLE_KEY>`.
//
// Secrets (supabase secrets set ...):
//   ANTHROPIC_API_KEY            required
//   TRANSLATION_WORKER_SECRET    optional override; by default the secret is
//                                read from Vault (created by the migration)
//   TRANSLATION_MODEL            optional, default claude-haiku-5-5
//   TRANSLATION_EFFORT           optional, low|medium|high, default medium
//
// Actions (POST body):
//   {}                                   process the queue (default)
//   {"action": "backfill"}               queue ALL content, then process
//   {"action": "retry_failed"}           re-queue failed jobs, then process
//   {"action": "status"}                 queue statistics

import Anthropic from "npm:@anthropic-ai/sdk@1.3.0";
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.45.4";

// ─── Configuration ──────────────────────────────────────────────────────────

const MODEL = Deno.env.get("TRANSLATION_MODEL") ?? "claude-haiku-5-5";
// Server-side refusal fallbacks exist for Opus/Fable/Sonnet 5.5, not for Haiku.
const SUPPORTS_FALLBACKS = !MODEL.startsWith("claude-haiku");
const EFFORT = (Deno.env.get("TRANSLATION_EFFORT") ?? "medium") as "low" | "medium" | "high";
const MAX_ATTEMPTS = 8;
const CLAIM_BATCH = 3;
/** Stop claiming new jobs after this much wall-clock time (edge limit ~150s). */
const TIME_BUDGET_MS = Number(Deno.env.get("TRANSLATION_TIME_BUDGET_MS") ?? "100000");
/** Max characters of German source per Claude request. Longer texts are split. */
const MAX_CHARS_PER_REQUEST = 14000;
/** Bump to force re-translation of everything (e.g. after prompt changes). */
const HASH_VERSION = "v2";
const FALLBACK_LANGUAGES = ["en", "ru", "es", "pl", "tr", "he"];

const LANGUAGE_NAMES: Record<string, string> = {
  en: "English",
  ru: "Russian",
  es: "Spanish",
  pl: "Polish",
  tr: "Turkish",
  he: "Modern Hebrew (without niqqud/vowel points)",
  fr: "French",
  it: "Italian",
  uk: "Ukrainian",
  ro: "Romanian",
  ar: "Arabic",
  fa: "Persian",
  pt: "Portuguese",
  nl: "Dutch",
};

const SYSTEM_PROMPT = `You are the professional translator of "Jugendkompass", a German Christian youth magazine app (articles, daily Bible verses, daily impulses/devotionals, short messages, videos, polls, magazine editions).

You receive a JSON object of German source segments and translate every segment into the requested target language.

Rules:
- Translate faithfully and completely. Never summarize, shorten, add notes or explanations.
- Use natural, warm, contemporary language suitable for teenagers and young adults, in the tone of the original. Keep the same form of address (informal "du" → informal in the target language where the language distinguishes it).
- Keep Christian terminology accurate (e.g. Gnade, Heiliger Geist, Evangelium, Gemeinde, Abendmahl) using the terms established in that language's churches.
- Bible quotations: when a segment quotes a recognizable Bible passage, render it the way it reads in a widely used modern Bible translation of the target language instead of translating word by word.
- Bible references (segment kind "reference" or references inside text): localize the book name and use the target language's citation convention, keep numbers unchanged. Examples: "Johannes 3,16" → en "John 3:16", es "Juan 3:16", ru "Иоанна 3:16", pl "J 3,16" or "Ewangelia Jana 3,16", tr "Yuhanna 3:16", he "יוחנן ג׳ 16" or "יוחנן 3:16". "1. Korinther 13,4-7" → en "1 Corinthians 13:4-7".
- HTML and Markdown: keep every tag, attribute, entity, link URL, image source, line break and list structure exactly as in the source. Translate only human-readable text (including alt/title attribute text). Never wrap the output in code fences.
- Keep URLs, e-mail addresses, @handles, #hashtags, emojis, numbers, dates' values and placeholders like {name} unchanged.
- Keep personal names and the brand "Jugendkompass" unchanged.
- Titles stay short and title-like; poll options stay short.
- Output must be a JSON object with exactly the same keys as the input and the translated strings as values.`;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-translation-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ─── Types ──────────────────────────────────────────────────────────────────

type JobType = "post" | "message" | "impulse" | "video" | "verse" | "poll" | "edition" | "category";
type SegmentKind = "title" | "body" | "html" | "verse" | "reference" | "question" | "option" | "name";

interface ClaimedJob {
  id: number;
  content_type: JobType;
  record_id: string;
  revision: number;
  attempts: number;
}

interface SourceField {
  /** field_name stored in the translation table, e.g. "title", "option:<uuid>" */
  name: string;
  text: string;
  kind: SegmentKind;
}

interface TranslationUnit {
  store: "content" | "entity";
  /** content_id (content store) or row id (entity store) */
  key: string;
  entityType?: "edition" | "category";
  contentLabel: string;
  fields: SourceField[];
  /** Field-name prefixes that are fully owned by this unit (stale ones get deleted). */
  ownedPrefixes?: string[];
}

interface ExistingTranslation {
  language: string;
  field_name: string;
  source_hash: string | null;
  status: string;
}

interface TranslatedRow {
  language: string;
  field_name: string;
  value: string;
  source_hash: string;
}

// ─── HTTP entry point ───────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const startedAt = Date.now();

  try {
    const supabaseUrl = requireEnv("SUPABASE_URL");
    const serviceRole = requireEnv("SUPABASE_SERVICE_ROLE_KEY");

    const supabase = createClient(supabaseUrl, serviceRole, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    if (!(await isAuthorized(req, serviceRole, supabase))) {
      return json({ ok: false, error: "unauthorized" }, 401);
    }

    const payload = await readPayload(req);
    const action = String(payload.action ?? "process");

    if (action === "status") {
      const { data, error } = await supabase.from("translation_queue_status").select("*");
      if (error) throw error;
      return json({ ok: true, status: data });
    }

    let queued: number | null = null;
    if (action === "backfill") {
      const { data, error } = await supabase.rpc("enqueue_translation_backfill");
      if (error) throw error;
      queued = Number(data ?? 0);
    } else if (action === "retry_failed") {
      const { data, error } = await supabase.rpc("retry_failed_translations");
      if (error) throw error;
      queued = Number(data ?? 0);
    }

    const anthropicKey = requireEnv("ANTHROPIC_API_KEY");
    const anthropic = new Anthropic({ apiKey: anthropicKey, maxRetries: 4, timeout: 120_000 });
    const languages = await loadActiveLanguages(supabase);
    const workerId = `edge-${crypto.randomUUID().slice(0, 8)}`;

    const results: Array<Record<string, unknown>> = [];

    while (Date.now() - startedAt < TIME_BUDGET_MS) {
      const { data: jobs, error } = await supabase.rpc("claim_translation_jobs", {
        p_batch_size: CLAIM_BATCH,
        p_worker: workerId,
      });
      if (error) throw new Error(`claim failed: ${error.message}`);
      const claimed = (jobs ?? []) as ClaimedJob[];
      if (claimed.length === 0) break;

      // Jobs run in parallel; inside a job, languages run in parallel too.
      const batchResults = await Promise.all(
        claimed.map((job) => processJob({ supabase, anthropic, job, languages })),
      );
      results.push(...batchResults);
    }

    return json({
      ok: true,
      action,
      queued,
      processed: results.length,
      languages,
      durationMs: Date.now() - startedAt,
      results,
    });
  } catch (error) {
    console.error("[translation] fatal", error);
    return json({ ok: false, error: stringifyError(error) }, 500);
  }
});

// ─── Job processing ─────────────────────────────────────────────────────────

async function processJob(args: {
  supabase: SupabaseClient;
  anthropic: Anthropic;
  job: ClaimedJob;
  languages: string[];
}): Promise<Record<string, unknown>> {
  const { supabase, anthropic, job, languages } = args;

  try {
    const unit = await loadUnit(supabase, job);
    let written = 0;
    let skipped = 0;

    if (unit) {
      const outcome = await translateUnit({ supabase, anthropic, unit, languages });
      written = outcome.written;
      skipped = outcome.skipped;
    }

    const { data: finish } = await supabase.rpc("finish_translation_job", {
      p_job_id: job.id,
      p_revision: job.revision,
      p_success: true,
      p_error: null,
      p_max_attempts: MAX_ATTEMPTS,
    });

    return {
      jobId: job.id,
      type: job.content_type,
      recordId: job.record_id,
      result: finish ?? "completed",
      written,
      skipped,
      missing: unit === null,
    };
  } catch (error) {
    const message = stringifyError(error);
    console.error(`[translation] job ${job.id} (${job.content_type}/${job.record_id}) failed:`, message);
    const { data: finish } = await supabase.rpc("finish_translation_job", {
      p_job_id: job.id,
      p_revision: job.revision,
      p_success: false,
      p_error: message,
      p_max_attempts: MAX_ATTEMPTS,
    });
    return { jobId: job.id, type: job.content_type, recordId: job.record_id, result: finish ?? "retry", error: message };
  }
}

async function translateUnit(args: {
  supabase: SupabaseClient;
  anthropic: Anthropic;
  unit: TranslationUnit;
  languages: string[];
}): Promise<{ written: number; skipped: number }> {
  const { supabase, anthropic, unit, languages } = args;

  const hashes = new Map<string, string>();
  for (const field of unit.fields) {
    hashes.set(field.name, await sourceHash(field.text));
  }

  const existing = await loadExisting(supabase, unit, languages);
  const existingByKey = new Map(existing.map((row) => [`${row.language}|${row.field_name}`, row]));

  await deleteStaleTranslations(supabase, unit, existing);

  let written = 0;
  let skipped = 0;

  const perLanguage = await Promise.all(
    languages.map(async (language) => {
      const todo = unit.fields.filter((field) => {
        const current = existingByKey.get(`${language}|${field.name}`);
        if (current?.status === "manual") return false; // never overwrite editor work
        return current?.source_hash !== hashes.get(field.name);
      });

      if (todo.length === 0) return { language, rows: [] as TranslatedRow[], skipped: unit.fields.length };

      const translated = await translateFields(anthropic, todo, language, unit.contentLabel);
      const rows: TranslatedRow[] = todo.map((field) => ({
        language,
        field_name: field.name,
        value: translated.get(field.name)!,
        source_hash: hashes.get(field.name)!,
      }));
      return { language, rows, skipped: unit.fields.length - todo.length };
    }),
  );

  const allRows = perLanguage.flatMap((entry) => entry.rows);
  skipped = perLanguage.reduce((sum, entry) => sum + entry.skipped, 0);

  if (allRows.length > 0) {
    await upsertTranslations(supabase, unit, allRows);
    written = allRows.length;
  }

  return { written, skipped };
}

// ─── Source loading ─────────────────────────────────────────────────────────

async function loadUnit(supabase: SupabaseClient, job: ClaimedJob): Promise<TranslationUnit | null> {
  const id = job.record_id;

  switch (job.content_type) {
    case "post": {
      const row = await single(supabase.from("posts").select("id, content_id, title, body").eq("id", id));
      if (!row?.content_id) return null;
      return contentUnit(row.content_id, "magazine article", [
        field("title", row.title, "title"),
        field("body", row.body, "html"),
      ]);
    }
    case "message": {
      const row = await single(supabase.from("messages").select("id, content_id, title, message").eq("id", Number(id)));
      if (!row?.content_id) return null;
      return contentUnit(row.content_id, "short message / announcement", [
        field("title", row.title, "title"),
        field("message", row.message, "body"),
      ]);
    }
    case "impulse": {
      const row = await single(supabase.from("impulses").select("id, content_id, title, impulse_text").eq("id", id));
      if (!row?.content_id) return null;
      return contentUnit(row.content_id, "daily impulse (short devotional)", [
        field("title", row.title, "title"),
        field("impulse_text", row.impulse_text, "body"),
      ]);
    }
    case "video": {
      const row = await single(supabase.from("videos").select("id, content_id, title, description").eq("id", Number(id)));
      if (!row?.content_id) return null;
      return contentUnit(row.content_id, "video", [
        field("title", row.title, "title"),
        field("description", row.description, "body"),
      ]);
    }
    case "verse": {
      const row = await single(supabase.from("verse_of_the_day").select("id, content_id, verse, reference").eq("id", id));
      if (!row?.content_id) return null;
      return contentUnit(row.content_id, "Bible verse of the day", [
        field("verse", row.verse, "verse"),
        field("reference", row.reference, "reference"),
      ]);
    }
    case "poll": {
      const row = await single(supabase.from("polls").select("id, content_id, question").eq("id", id));
      if (!row?.content_id) return null;
      const { data: options, error } = await supabase
        .from("poll_options")
        .select("id, option_text")
        .eq("poll_id", id);
      if (error) throw new Error(`load poll options: ${error.message}`);
      const unit = contentUnit(row.content_id, "poll", [
        field("question", row.question, "question"),
        ...(options ?? []).map((option: { id: string; option_text: string }) =>
          field(`option:${option.id}`, option.option_text, "option")
        ),
      ]);
      unit.ownedPrefixes = ["option:"];
      return unit;
    }
    case "edition": {
      const row = await single(supabase.from("editions").select("id, name, title, body").eq("id", id));
      if (!row) return null;
      return {
        store: "entity",
        entityType: "edition",
        key: String(row.id),
        contentLabel: "magazine edition",
        fields: compact([
          field("name", row.name, "name"),
          field("title", row.title, "title"),
          field("body", row.body, "html"),
        ]),
      };
    }
    case "category": {
      const row = await single(supabase.from("categories").select("id, name").eq("id", id));
      if (!row) return null;
      return {
        store: "entity",
        entityType: "category",
        key: String(row.id),
        contentLabel: "article category / tag (one or two words)",
        fields: compact([field("name", row.name, "name")]),
      };
    }
    default:
      throw new Error(`Unsupported job type ${job.content_type}`);
  }
}

function contentUnit(contentId: string, label: string, fields: Array<SourceField | null>): TranslationUnit {
  return { store: "content", key: String(contentId), contentLabel: label, fields: compact(fields) };
}

function field(name: string, value: unknown, kind: SegmentKind): SourceField | null {
  const text = typeof value === "string" ? value.trim() : "";
  if (!text) return null;
  return { name, text, kind };
}

function compact<T>(items: Array<T | null>): T[] {
  return items.filter((item): item is T => item !== null);
}

// deno-lint-ignore no-explicit-any
async function single(query: any): Promise<any | null> {
  const { data, error } = await query.maybeSingle();
  if (error) throw new Error(error.message);
  return data ?? null;
}

// ─── Translation storage ────────────────────────────────────────────────────

async function loadExisting(
  supabase: SupabaseClient,
  unit: TranslationUnit,
  languages: string[],
): Promise<ExistingTranslation[]> {
  const query = unit.store === "content"
    ? supabase
      .from("content_translations")
      .select("language, field_name, source_hash, status")
      .eq("content_id", unit.key)
    : supabase
      .from("entity_translations")
      .select("language, field_name, source_hash, status")
      .eq("entity_type", unit.entityType!)
      .eq("entity_id", unit.key);

  const { data, error } = await query.in("language", languages);
  if (error) throw new Error(`load existing translations: ${error.message}`);
  return (data ?? []) as ExistingTranslation[];
}

/** Removes automatic translations whose source field no longer exists (cleared description, deleted poll option). */
async function deleteStaleTranslations(
  supabase: SupabaseClient,
  unit: TranslationUnit,
  existing: ExistingTranslation[],
): Promise<void> {
  const current = new Set(unit.fields.map((f) => f.name));
  const knownFixed = new Set(["title", "body", "message", "impulse_text", "description", "verse", "reference", "question", "name"]);

  const stale = existing.filter((row) =>
    row.status !== "manual" &&
    !current.has(row.field_name) &&
    (knownFixed.has(row.field_name) || (unit.ownedPrefixes ?? []).some((p) => row.field_name.startsWith(p)))
  );
  if (stale.length === 0) return;

  const staleFields = Array.from(new Set(stale.map((row) => row.field_name)));
  const query = unit.store === "content"
    ? supabase.from("content_translations").delete().eq("content_id", unit.key)
    : supabase.from("entity_translations").delete().eq("entity_type", unit.entityType!).eq("entity_id", unit.key);

  const { error } = await query.in("field_name", staleFields).neq("status", "manual");
  if (error) console.warn("[translation] stale cleanup failed:", error.message);
}

async function upsertTranslations(supabase: SupabaseClient, unit: TranslationUnit, rows: TranslatedRow[]): Promise<void> {
  if (unit.store === "content") {
    const { error } = await supabase.from("content_translations").upsert(
      rows.map((row) => ({ content_id: unit.key, status: "auto", ...row })),
      { onConflict: "content_id,language,field_name" },
    );
    if (error) throw new Error(`upsert content_translations: ${error.message}`);
  } else {
    const { error } = await supabase.from("entity_translations").upsert(
      rows.map((row) => ({ entity_type: unit.entityType, entity_id: unit.key, status: "auto", ...row })),
      { onConflict: "entity_type,entity_id,language,field_name" },
    );
    if (error) throw new Error(`upsert entity_translations: ${error.message}`);
  }
}

async function loadActiveLanguages(supabase: SupabaseClient): Promise<string[]> {
  const { data, error } = await supabase.from("translation_targets").select("language_code").eq("is_active", true);
  if (error || !data || data.length === 0) {
    if (error) console.warn("[translation] translation_targets unavailable:", error.message);
    return FALLBACK_LANGUAGES;
  }
  const langs = data
    .map((row: { language_code: string }) => row.language_code.trim().toLowerCase())
    .filter((code: string) => code.length > 0 && code !== "de");
  return Array.from(new Set(langs)).sort((a, b) => (a === "en" ? -1 : b === "en" ? 1 : a.localeCompare(b)));
}

// ─── Claude translation ─────────────────────────────────────────────────────

interface Segment {
  key: string;
  fieldName: string;
  kind: SegmentKind;
  text: string;
}

/** Translates the given fields into one language. Returns field_name → translated text. */
async function translateFields(
  anthropic: Anthropic,
  fields: SourceField[],
  language: string,
  contentLabel: string,
): Promise<Map<string, string>> {
  // 1) split long fields into segments at paragraph / HTML block boundaries
  const segments: Segment[] = [];
  fields.forEach((f, fieldIndex) => {
    splitIntoChunks(f.text, MAX_CHARS_PER_REQUEST).forEach((chunk, chunkIndex) => {
      segments.push({ key: `s${fieldIndex}_${chunkIndex}`, fieldName: f.name, kind: f.kind, text: chunk });
    });
  });

  // 2) group segments into requests that respect the size budget
  const requests: Segment[][] = [];
  let current: Segment[] = [];
  let size = 0;
  for (const segment of segments) {
    if (current.length > 0 && size + segment.text.length > MAX_CHARS_PER_REQUEST) {
      requests.push(current);
      current = [];
      size = 0;
    }
    current.push(segment);
    size += segment.text.length;
  }
  if (current.length > 0) requests.push(current);

  // 3) translate
  const translatedSegments = new Map<string, string>();
  for (const group of requests) {
    const output = await translateSegmentsWithValidation(anthropic, group, language, contentLabel);
    for (const [key, value] of output) translatedSegments.set(key, value);
  }

  // 4) re-assemble fields
  const result = new Map<string, string>();
  for (const f of fields) {
    const parts = segments.filter((s) => s.fieldName === f.name).map((s) => translatedSegments.get(s.key) ?? "");
    result.set(f.name, parts.join(f.kind === "html" ? "" : "\n\n").trim());
  }
  return result;
}

async function translateSegmentsWithValidation(
  anthropic: Anthropic,
  segments: Segment[],
  language: string,
  contentLabel: string,
): Promise<Map<string, string>> {
  let lastError: unknown = null;
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const output = await callClaude(anthropic, segments, language, contentLabel);
      for (const segment of segments) {
        validateSegment(segment, output.get(segment.key));
      }
      return output;
    } catch (error) {
      lastError = error;
      console.warn(`[translation] ${language} attempt ${attempt} failed: ${stringifyError(error)}`);
      if (error instanceof Anthropic.AuthenticationError || error instanceof Anthropic.PermissionDeniedError) {
        break; // retrying cannot help
      }
    }
  }
  throw new Error(`translation to ${language} failed: ${stringifyError(lastError)}`);
}

async function callClaude(
  anthropic: Anthropic,
  segments: Segment[],
  language: string,
  contentLabel: string,
): Promise<Map<string, string>> {
  const languageName = LANGUAGE_NAMES[language] ?? language;

  const input: Record<string, { kind: SegmentKind; text: string }> = {};
  const properties: Record<string, { type: "string" }> = {};
  for (const segment of segments) {
    input[segment.key] = { kind: segment.kind, text: segment.text };
    properties[segment.key] = { type: "string" };
  }

  const userText = [
    `Target language: ${languageName} (code "${language}")`,
    `Content type: ${contentLabel}`,
    `Translate the "text" of every segment. Return {"<key>": "<translation>"} for all keys.`,
    "",
    JSON.stringify(input, null, 2),
  ].join("\n");

  const sourceChars = segments.reduce((sum, s) => sum + s.text.length, 0);
  // Hebrew/Russian need more tokens per character; leave generous headroom.
  const maxTokens = Math.min(64000, Math.max(8000, Math.ceil(sourceChars * 1.5) + 4000));

  const stream = anthropic.beta.messages.stream({
    model: MODEL,
    max_tokens: maxTokens,
    ...(SUPPORTS_FALLBACKS
      ? { betas: ["server-side-fallback-2026-07-01"], fallbacks: "default" as const }
      : {}),
    system: [{ type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
    output_config: {
      effort: EFFORT,
      format: {
        type: "json_schema",
        schema: {
          type: "object",
          properties,
          required: Object.keys(properties),
          additionalProperties: false,
        },
      },
    },
    messages: [{ role: "user", content: userText }],
  });

  const message = await stream.finalMessage();

  if (message.stop_reason === "refusal") {
    throw new Error(`model refused (${message.stop_details?.category ?? "unknown"})`);
  }
  if (message.stop_reason === "max_tokens") {
    throw new Error("output truncated (max_tokens)");
  }

  const text = message.content
    .filter((block): block is Anthropic.Beta.BetaTextBlock => block.type === "text")
    .map((block) => block.text)
    .join("");

  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new Error(`invalid JSON from model: ${text.slice(0, 200)}`);
  }

  const out = new Map<string, string>();
  for (const segment of segments) {
    const value = parsed[segment.key];
    if (typeof value === "string") out.set(segment.key, value.trim());
  }
  return out;
}

function validateSegment(segment: Segment, translated: string | undefined): void {
  if (!translated || translated.trim().length === 0) {
    throw new Error(`segment ${segment.key} missing in output`);
  }

  // Implausible length → probably truncated or summarized.
  if (segment.text.length > 200 && translated.length < segment.text.length * 0.35) {
    throw new Error(`segment ${segment.key} suspiciously short (${translated.length}/${segment.text.length})`);
  }

  // HTML structure must survive.
  const sourceTags = countTags(segment.text);
  if (sourceTags > 0) {
    const translatedTags = countTags(translated);
    if (Math.abs(sourceTags - translatedTags) > Math.max(2, Math.round(sourceTags * 0.1))) {
      throw new Error(`segment ${segment.key} HTML tags changed (${sourceTags} → ${translatedTags})`);
    }
  }

  if (/^```/.test(translated.trim())) {
    throw new Error(`segment ${segment.key} wrapped in code fence`);
  }
}

function countTags(text: string): number {
  return (text.match(/<\/?[a-zA-Z][^>]*>/g) ?? []).length;
}

/** Splits text at HTML block ends / blank lines / sentences, never inside a tag. */
function splitIntoChunks(text: string, maxLength: number): string[] {
  if (text.length <= maxLength) return [text];

  const isHtml = /<\/(p|div|h[1-6]|li|ul|ol|blockquote|figure|table)>/i.test(text);
  const pieces = isHtml
    ? text.split(/(?<=<\/(?:p|div|h[1-6]|li|ul|ol|blockquote|figure|table)>)/i)
    : text.split(/(?<=\n\s*\n)/);

  const chunks: string[] = [];
  let buffer = "";
  for (const piece of pieces) {
    if (piece.length > maxLength) {
      if (buffer) {
        chunks.push(buffer);
        buffer = "";
      }
      // last resort: sentence boundaries
      let rest = piece;
      while (rest.length > maxLength) {
        let cut = rest.lastIndexOf(". ", maxLength);
        if (cut < maxLength * 0.5) cut = rest.lastIndexOf(" ", maxLength);
        if (cut <= 0) cut = maxLength;
        chunks.push(rest.slice(0, cut + 1));
        rest = rest.slice(cut + 1);
      }
      buffer = rest;
      continue;
    }
    if (buffer.length + piece.length > maxLength) {
      chunks.push(buffer);
      buffer = piece;
    } else {
      buffer += piece;
    }
  }
  if (buffer) chunks.push(buffer);
  return chunks.filter((c) => c.trim().length > 0);
}

// ─── Helpers ────────────────────────────────────────────────────────────────

async function sourceHash(text: string): Promise<string> {
  const bytes = new TextEncoder().encode(`${HASH_VERSION}:${text}`);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

let cachedWorkerSecret: string | null = null;

/** Secret shared with the database (Vault), optionally overridden by env. */
async function workerSecret(supabase: SupabaseClient): Promise<string | null> {
  const fromEnv = Deno.env.get("TRANSLATION_WORKER_SECRET");
  if (fromEnv) return fromEnv;
  if (cachedWorkerSecret) return cachedWorkerSecret;
  const { data, error } = await supabase.rpc("get_translation_worker_secret");
  if (error) {
    console.warn("[translation] cannot read worker secret:", error.message);
    return null;
  }
  cachedWorkerSecret = typeof data === "string" && data.length > 0 ? data : null;
  return cachedWorkerSecret;
}

async function isAuthorized(req: Request, serviceRole: string, supabase: SupabaseClient): Promise<boolean> {
  const bearer = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (bearer && timingSafeEqual(bearer, serviceRole)) return true;

  const headerSecret = req.headers.get("x-translation-secret");
  if (!headerSecret) return false;
  const secret = await workerSecret(supabase);
  return !!secret && timingSafeEqual(secret, headerSecret);
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing environment variable ${name}`);
  return value;
}

async function readPayload(req: Request): Promise<Record<string, unknown>> {
  if (req.method !== "POST") return {};
  try {
    const body = await req.json();
    return body && typeof body === "object" ? body as Record<string, unknown> : {};
  } catch {
    return {};
  }
}

function stringifyError(error: unknown): string {
  if (!error) return "Unknown error";
  if (typeof error === "string") return error;
  if (error instanceof Error) return `${error.name}: ${error.message}`;
  try {
    return JSON.stringify(error);
  } catch {
    return String(error);
  }
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload, null, 2), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
