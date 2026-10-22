// @ts-nocheck

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type JobStatus = "pending" | "processing" | "completed" | "failed";
type ContentType = "post" | "message" | "impulse" | "video" | "verse";

interface TranslationJob {
  id: number;
  content_type: ContentType;
  record_id: string;
  content_id: string;
  status: JobStatus;
  attempts: number;
  next_retry_at: string;
}

interface SourceRecord {
  id: string;
  content_id: string;
  fields: Record<string, string>;
}

interface WorkerPayload extends Record<string, unknown> {
  enqueueBackfill?: boolean;
  backfillMaxRows?: number;
  backfillLanguage?: string;
  batchSize?: number;
  dryRun?: boolean;
  languages?: string[];
  contentTypes?: string[];
  geminiApiKey?: string;
}

const MAX_ATTEMPTS = Number(Deno.env.get("TRANSLATION_MAX_ATTEMPTS") ?? "8");
const DEFAULT_BATCH_SIZE = Number(Deno.env.get("TRANSLATION_BATCH_SIZE") ?? "15");
const DEFAULT_TARGET_LANGUAGES = ["en", "ru", "pl", "es", "tr", "he"];
const DEFAULT_TARGET_CONTENT_TYPES: ContentType[] = ["post", "message", "impulse", "video", "verse"];
const GEMINI_MODELS = (Deno.env.get("GEMINI_TRANSLATION_MODELS") ?? "gemini-3.6-flash,gemini-2.5-flash,gemini-3.5-flash-lite")
  .split(",")
  .map((model) => model.trim())
  .filter((model) => model.length > 0);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

let runtimeGeminiApiKey: string | null = null;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRole) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    }

    const supabase = createClient(supabaseUrl, serviceRole);

    const payload = await readPayload(req);
    if (payload.enqueueBackfill === true) {
      const maxRows = Number(payload.backfillMaxRows ?? 8000);
      const backfillLanguage = typeof payload.backfillLanguage === "string"
        ? payload.backfillLanguage.trim().toLowerCase()
        : null;

      let queuedJobs = 0;

      const allResult = await supabase.rpc("enqueue_translation_backfill_for_all", {
        max_rows_per_type: maxRows,
        target_language: backfillLanguage,
      });

      if (!allResult.error) {
        queuedJobs = Number(allResult.data ?? 0);
      } else {
        const postFallback = await supabase.rpc("enqueue_translation_backfill_for_posts", {
          max_rows: maxRows,
        });
        if (postFallback.error) throw postFallback.error;
        queuedJobs = Number(postFallback.data ?? 0);
      }

      return json({
        ok: true,
        action: "backfill-enqueue",
        queuedJobs,
      });
    }

    runtimeGeminiApiKey =
      (typeof payload.geminiApiKey === "string" && payload.geminiApiKey.trim().length > 0)
        ? payload.geminiApiKey.trim()
        : Deno.env.get("GEMINI_API_KEY");

    if (!runtimeGeminiApiKey) {
      throw new Error("Missing Gemini API key. Provide `geminiApiKey` in payload or set `GEMINI_API_KEY` secret.");
    }

    const batchSize = Number(payload.batchSize ?? DEFAULT_BATCH_SIZE);
    const dryRun = payload.dryRun === true;
    const languages = resolveRequestedLanguages(payload, await loadActiveLanguages(supabase));
    const contentTypes = resolveRequestedContentTypes(payload);

    const jobs = await loadPendingJobs(supabase, batchSize, contentTypes);
    if (jobs.length === 0) {
      return json({ ok: true, processed: 0, message: "No pending translation jobs." });
    }

    const results: Array<Record<string, unknown>> = [];

    for (const job of jobs) {
      const claim = await claimJob(supabase, job.id);
      if (!claim) continue;

      try {
        const sourceRecord = await loadSourceRecord(supabase, job);
        if (!sourceRecord || !sourceRecord.content_id) {
          await failJob(supabase, job.id, job.attempts, `Record not found or missing content_id for ${job.content_type}.`);
          results.push({ jobId: job.id, status: "failed", reason: "missing_record", contentType: job.content_type });
          continue;
        }

        const translatedFields = await translateMissingFields({
          supabase,
          sourceRecord,
          targetLanguages: languages,
          dryRun,
        });

        await completeJob(supabase, job.id);
        results.push({
          jobId: job.id,
          status: "completed",
          contentType: job.content_type,
          translatedFields,
          dryRun,
        });
      } catch (error) {
        await failJob(supabase, job.id, job.attempts, stringifyError(error));
        results.push({
          jobId: job.id,
          status: "failed",
          contentType: job.content_type,
          error: stringifyError(error),
        });
      }
    }

    return json({
      ok: true,
      processed: results.length,
      results,
      activeLanguages: languages,
      activeContentTypes: contentTypes,
      dryRun,
    });
  } catch (error) {
    return json(
      {
        ok: false,
        error: stringifyError(error),
      },
      500,
    );
  }
});

async function readPayload(req: Request): Promise<WorkerPayload> {
  if (req.method !== "POST") return {};
  try {
    const body = await req.json();
    if (body && typeof body === "object") return body as WorkerPayload;
    return {};
  } catch (_) {
    return {};
  }
}

function resolveRequestedLanguages(payload: Record<string, unknown>, activeLanguages: string[]): string[] {
  const requested = payload.languages;
  if (!Array.isArray(requested) || requested.length === 0) {
    return prioritizeLanguages(activeLanguages);
  }

  const normalized = requested
    .map((item) => String(item ?? "").trim().toLowerCase())
    .filter((item) => item.length > 0 && item !== "de");

  const unique = Array.from(new Set(normalized));
  if (unique.length === 0) return activeLanguages;

  return prioritizeLanguages(unique);
}

function resolveRequestedContentTypes(payload: Record<string, unknown>): ContentType[] {
  const requested = payload.contentTypes;
  if (!Array.isArray(requested) || requested.length === 0) {
    return DEFAULT_TARGET_CONTENT_TYPES;
  }

  const normalized = requested
    .map((item) => String(item ?? "").trim().toLowerCase())
    .filter((item): item is ContentType =>
      item === "post" || item === "message" || item === "impulse" || item === "video" || item === "verse"
    );

  const unique = Array.from(new Set(normalized));
  if (unique.length === 0) return DEFAULT_TARGET_CONTENT_TYPES;

  return unique;
}

async function loadActiveLanguages(supabase: ReturnType<typeof createClient>): Promise<string[]> {
  const { data, error } = await supabase
    .from("translation_targets")
    .select("language_code")
    .eq("is_active", true);

  if (error || !data) {
    console.warn("[translation-jobs] Failed to load translation_targets, fallback to defaults:", error?.message);
    return DEFAULT_TARGET_LANGUAGES;
  }

  const rows = (data ?? []) as Array<{ language_code: string }>;
  const languages = rows
    .map((row: { language_code: string }) => row.language_code.trim().toLowerCase())
    .filter((lang: string) => lang.length > 0 && lang !== "de");

  return prioritizeLanguages(Array.from(new Set<string>(languages.length > 0 ? languages : DEFAULT_TARGET_LANGUAGES)));
}

function prioritizeLanguages(languages: string[]): string[] {
  const normalized = languages
    .map((lang) => String(lang ?? "").trim().toLowerCase())
    .filter((lang) => lang.length > 0 && lang !== "de");

  const unique = Array.from(new Set(normalized));
  unique.sort((left, right) => {
    if (left === "en" && right !== "en") return -1;
    if (right === "en" && left !== "en") return 1;
    return left.localeCompare(right);
  });

  return unique;
}

async function loadPendingJobs(
  supabase: ReturnType<typeof createClient>,
  batchSize: number,
  contentTypes: ContentType[],
): Promise<TranslationJob[]> {
  const nowIso = new Date().toISOString();

  const { data, error } = await supabase
    .from("translation_jobs")
    .select("id, content_type, record_id, content_id, status, attempts, next_retry_at")
    .in("content_type", contentTypes)
    .in("status", ["pending", "failed"])
    .lte("next_retry_at", nowIso)
    .order("created_at", { ascending: true })
    .limit(batchSize);

  if (error) {
    throw new Error(`Failed to load jobs: ${error.message}`);
  }

  return (data ?? []) as TranslationJob[];
}

async function claimJob(supabase: ReturnType<typeof createClient>, jobId: number): Promise<boolean> {
  const { data, error } = await supabase
    .from("translation_jobs")
    .update({
      status: "processing",
      locked_at: new Date().toISOString(),
      locked_by: "process-translation-jobs",
      last_error: null,
    })
    .eq("id", jobId)
    .in("status", ["pending", "failed"])
    .select("id")
    .maybeSingle();

  if (error) {
    console.warn("[translation-jobs] claimJob failed", jobId, error.message);
    return false;
  }

  return !!data;
}

async function loadSourceRecord(
  supabase: ReturnType<typeof createClient>,
  job: TranslationJob,
): Promise<SourceRecord | null> {
  if (job.content_type === "post") {
    const { data, error } = await supabase
      .from("posts")
      .select("id, content_id, title, body")
      .eq("id", job.record_id)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to load post ${job.record_id}: ${error.message}`);
    }

    if (!data) return null;

    return {
      id: String(data.id),
      content_id: String(data.content_id ?? ""),
      fields: {
        title: String(data.title ?? ""),
        body: String(data.body ?? ""),
      },
    };
  }

  if (job.content_type === "message") {
    const { data, error } = await supabase
      .from("messages")
      .select("id, content_id, title, message")
      .eq("id", Number(job.record_id))
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to load message ${job.record_id}: ${error.message}`);
    }

    if (!data) return null;

    return {
      id: String(data.id),
      content_id: String(data.content_id ?? ""),
      fields: {
        title: String(data.title ?? ""),
        message: String(data.message ?? ""),
      },
    };
  }

  if (job.content_type === "impulse") {
    const { data, error } = await supabase
      .from("impulses")
      .select("id, content_id, title, impulse_text")
      .eq("id", job.record_id)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to load impulse ${job.record_id}: ${error.message}`);
    }

    if (!data) return null;

    return {
      id: String(data.id),
      content_id: String(data.content_id ?? ""),
      fields: {
        title: String(data.title ?? ""),
        impulse_text: String(data.impulse_text ?? ""),
      },
    };
  }

  if (job.content_type === "video") {
    const { data, error } = await supabase
      .from("videos")
      .select("id, content_id, title, description")
      .eq("id", Number(job.record_id))
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to load video ${job.record_id}: ${error.message}`);
    }

    if (!data) return null;

    return {
      id: String(data.id),
      content_id: String(data.content_id ?? ""),
      fields: {
        title: String(data.title ?? ""),
        description: String(data.description ?? ""),
      },
    };
  }

  if (job.content_type === "verse") {
    const { data, error } = await supabase
      .from("verse_of_the_day")
      .select("id, content_id, verse, reference")
      .eq("id", job.record_id)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to load verse ${job.record_id}: ${error.message}`);
    }

    if (!data) return null;

    return {
      id: String(data.id),
      content_id: String(data.content_id ?? ""),
      fields: {
        verse: String(data.verse ?? ""),
        reference: String(data.reference ?? ""),
      },
    };
  }

  return null;
}

async function translateMissingFields(args: {
  supabase: ReturnType<typeof createClient>;
  sourceRecord: SourceRecord;
  targetLanguages: string[];
  dryRun: boolean;
}): Promise<number> {
  const { supabase, sourceRecord, targetLanguages, dryRun } = args;
  const sourceFieldNames = Object.keys(sourceRecord.fields);
  if (sourceFieldNames.length === 0) return 0;

  const { data: existingRows, error: existingError } = await supabase
    .from("content_translations")
    .select("language, field_name")
    .eq("content_id", sourceRecord.content_id)
    .in("language", targetLanguages)
    .in("field_name", sourceFieldNames);

  if (existingError) {
    throw new Error(`Failed to read existing translations: ${existingError.message}`);
  }

  const translationRows = (existingRows ?? []) as Array<{ language: string; field_name: string }>;
  const existing = new Set(
    translationRows.map((row: { language: string; field_name: string }) => `${row.language}:${row.field_name}`),
  );

  let translatedFieldCount = 0;

  for (const language of targetLanguages) {
    const fieldsNeedingTranslation = sourceFieldNames.filter((fieldName) => {
      const key = `${language}:${fieldName}`;
      const sourceValue = sourceRecord.fields[fieldName]?.trim() ?? "";
      return sourceValue.length > 0 && !existing.has(key);
    });

    if (fieldsNeedingTranslation.length === 0) {
      continue;
    }

    const sourceTexts = fieldsNeedingTranslation
      .map((fieldName) => sourceRecord.fields[fieldName] ?? "");
    const translatedTexts = await translateGermanTextList(sourceTexts, language);

    for (let index = 0; index < fieldsNeedingTranslation.length; index++) {
      const fieldName = fieldsNeedingTranslation[index];
      const translatedValue = translatedTexts[index]?.trim() ?? "";
      if (!translatedValue) continue;

      translatedFieldCount += 1;
      if (!dryRun) {
        const { error } = await supabase
          .from("content_translations")
          .upsert(
            {
              content_id: sourceRecord.content_id,
              language,
              field_name: fieldName,
              value: translatedValue,
            },
            { onConflict: "content_id,language,field_name" },
          );
        if (error) {
          throw new Error(`Failed to upsert translation ${language}/${fieldName}: ${error.message}`);
        }
      }
    }
  }

  return translatedFieldCount;
}

async function translateGermanTextList(texts: string[], targetLanguage: string): Promise<string[]> {
  if (texts.length === 0) return [];
  if (texts.length === 1) {
    return [await translateGermanText(texts[0], targetLanguage)];
  }

  const separator = "\n\n[[[JK_FIELD_SPLIT]]]\n\n";
  const payload = texts.join(separator);

  const translated = await translateGermanText(payload, targetLanguage);
  if (!translated.includes("[[[JK_FIELD_SPLIT]]]") && !translated.includes("JK_FIELD_SPLIT")) {
    const fallback: string[] = [];
    for (const text of texts) {
      fallback.push(await translateGermanText(text, targetLanguage));
    }
    return fallback;
  }

  const parts = translated
    .split(/\[\[\[JK_FIELD_SPLIT\]\]\]|JK_FIELD_SPLIT/)
    .map((part) => part.trim());

  if (parts.length !== texts.length) {
    const fallback: string[] = [];
    for (const text of texts) {
      fallback.push(await translateGermanText(text, targetLanguage));
    }
    return fallback;
  }

  return parts;
}

async function translateGermanText(text: string, targetLanguage: string): Promise<string> {
  const cleaned = text.trim();
  if (!cleaned) return cleaned;
  if (targetLanguage === "de") return cleaned;

  return await translateWithGeminiRetry(cleaned, targetLanguage);
}

async function translateWithGeminiRetry(text: string, targetLanguage: string): Promise<string> {
  const chunks = splitText(text, 2500);
  const translatedChunks: string[] = [];

  for (const chunk of chunks) {
    translatedChunks.push(await translateChunkWithGeminiRetry(chunk, targetLanguage));
  }

  return translatedChunks.join("\n\n");
}

async function translateChunkWithGeminiRetry(text: string, targetLanguage: string): Promise<string> {
  const attempts = 3;
  let lastError: unknown;

  for (let i = 1; i <= attempts; i++) {
    try {
      return await translateChunkWithGemini(text, targetLanguage);
    } catch (error) {
      lastError = error;
      if (i < attempts) {
        await delay(500 * i);
      }
    }
  }

  throw new Error(`Gemini retries exhausted: ${stringifyError(lastError)}`);
}

async function translateChunkWithGemini(text: string, targetLanguage: string): Promise<string> {
  const apiKey = runtimeGeminiApiKey;
  if (!apiKey) {
    throw new Error("Missing Gemini API key at runtime");
  }

  const prompt = [
    "Translate the following German text into the target language.",
    "Return only translated text.",
    "Preserve punctuation, markdown, html tags, links, and line breaks.",
    "Do not add explanations.",
    `Target language code: ${targetLanguage}`,
    "Text:",
    text,
  ].join("\n");

  const models = GEMINI_MODELS.length > 0 ? GEMINI_MODELS : ["gemini-3.6-flash"];
  let lastError: string | null = null;

  for (const model of models) {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          generationConfig: {
            temperature: 0.1,
            topP: 0.8,
            maxOutputTokens: 8192,
          },
          contents: [
            {
              role: "user",
              parts: [{ text: prompt }],
            },
          ],
        }),
      },
    );

    if (!response.ok) {
      const body = await response.text();
      lastError = `Model ${model} HTTP ${response.status}: ${body}`;
      continue;
    }

    const json = await response.json();
    const translatedText = json?.candidates?.[0]?.content?.parts
      ?.map((part: { text?: string }) => part?.text ?? "")
      .join("")
      .trim();

    if (typeof translatedText === "string" && translatedText.trim()) {
      return translatedText;
    }

    lastError = `Model ${model} returned empty translation`;
  }

  throw new Error(lastError ?? "All Gemini models failed");
}

function splitText(text: string, maxLength: number): string[] {
  if (text.length <= maxLength) return [text];

  const paragraphs = text.split(/\n{2,}/g);
  const chunks: string[] = [];

  for (const paragraph of paragraphs) {
    if (paragraph.length <= maxLength) {
      chunks.push(paragraph);
      continue;
    }

    let start = 0;
    while (start < paragraph.length) {
      let end = Math.min(start + maxLength, paragraph.length);
      if (end < paragraph.length) {
        const breakAt = paragraph.lastIndexOf(" ", end);
        if (breakAt > start) end = breakAt;
      }
      chunks.push(paragraph.slice(start, end).trim());
      start = end;
    }
  }

  return chunks.filter((chunk) => chunk.trim().length > 0);
}

async function completeJob(supabase: ReturnType<typeof createClient>, jobId: number): Promise<void> {
  const { error } = await supabase
    .from("translation_jobs")
    .update({
      status: "completed",
      last_error: null,
      locked_at: null,
      locked_by: null,
    })
    .eq("id", jobId);

  if (error) {
    throw new Error(`Failed to complete job ${jobId}: ${error.message}`);
  }
}

async function failJob(
  supabase: ReturnType<typeof createClient>,
  jobId: number,
  attemptsDone: number,
  reason: string,
): Promise<void> {
  const nextAttempts = attemptsDone + 1;
  const terminal = nextAttempts >= MAX_ATTEMPTS;
  const retryDelayMinutes = Math.min(60, Math.pow(2, Math.min(nextAttempts, 6)));
  const nextRetryAt = terminal
    ? new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()
    : new Date(Date.now() + retryDelayMinutes * 60 * 1000).toISOString();

  const { error } = await supabase
    .from("translation_jobs")
    .update({
      status: terminal ? "failed" : "pending",
      attempts: nextAttempts,
      next_retry_at: nextRetryAt,
      last_error: reason.slice(0, 2000),
      locked_at: null,
      locked_by: null,
    })
    .eq("id", jobId);

  if (error) {
    console.error("[translation-jobs] failJob update error", error.message);
  }
}

function stringifyError(error: unknown): string {
  if (!error) return "Unknown error";
  if (typeof error === "string") return error;
  if (error instanceof Error) return `${error.name}: ${error.message}`;
  try {
    return JSON.stringify(error);
  } catch (_) {
    return String(error);
  }
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload, null, 2), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
