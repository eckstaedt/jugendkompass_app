-- Stable translation automation for posts (articles)
-- - Queues translation jobs automatically on post insert/update
-- - Tracks active target languages (includes Hebrew)
-- - Adds a backfill RPC to enqueue missing translations for existing posts

BEGIN;

-- 1) Languages managed by translation automation
CREATE TABLE IF NOT EXISTS public.translation_targets (
  language_code text PRIMARY KEY,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.translation_targets (language_code, is_active)
VALUES
  ('en', true),
  ('ru', true),
  ('pl', true),
  ('es', true),
  ('tr', true),
  ('he', true)
ON CONFLICT (language_code) DO UPDATE
SET is_active = EXCLUDED.is_active,
    updated_at = now();

-- 2) Ensure translations are idempotent and upsert-safe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname = 'content_translations_content_lang_field_uidx'
  ) THEN
    CREATE UNIQUE INDEX content_translations_content_lang_field_uidx
      ON public.content_translations (content_id, language, field_name);
  END IF;
END
$$;

-- 3) Translation job queue
CREATE TABLE IF NOT EXISTS public.translation_jobs (
  id bigserial PRIMARY KEY,
  content_type text NOT NULL,
  record_id text NOT NULL,
  content_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  attempts integer NOT NULL DEFAULT 0,
  next_retry_at timestamptz NOT NULL DEFAULT now(),
  last_error text,
  locked_at timestamptz,
  locked_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT translation_jobs_status_check
    CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  CONSTRAINT translation_jobs_content_type_check
    CHECK (content_type IN ('post')),
  CONSTRAINT translation_jobs_record_unique UNIQUE (content_type, record_id)
);

CREATE INDEX IF NOT EXISTS translation_jobs_status_retry_idx
  ON public.translation_jobs (status, next_retry_at, created_at);

CREATE INDEX IF NOT EXISTS translation_jobs_content_id_idx
  ON public.translation_jobs (content_id);

-- 4) Trigger helper to keep updated_at fresh
CREATE OR REPLACE FUNCTION public.set_translation_jobs_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_translation_jobs_updated_at ON public.translation_jobs;
CREATE TRIGGER trg_set_translation_jobs_updated_at
BEFORE UPDATE ON public.translation_jobs
FOR EACH ROW
EXECUTE FUNCTION public.set_translation_jobs_updated_at();

-- 5) Enqueue post translation jobs automatically
CREATE OR REPLACE FUNCTION public.enqueue_post_translation_job()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.content_id IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.translation_jobs (
    content_type,
    record_id,
    content_id,
    status,
    attempts,
    next_retry_at,
    last_error,
    locked_at,
    locked_by
  ) VALUES (
    'post',
    NEW.id::text,
    NEW.content_id,
    'pending',
    0,
    now(),
    NULL,
    NULL,
    NULL
  )
  ON CONFLICT (content_type, record_id)
  DO UPDATE
  SET content_id = EXCLUDED.content_id,
      status = 'pending',
      attempts = 0,
      next_retry_at = now(),
      last_error = NULL,
      locked_at = NULL,
      locked_by = NULL,
      updated_at = now();

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enqueue_post_translation_job ON public.posts;
CREATE TRIGGER trg_enqueue_post_translation_job
AFTER INSERT OR UPDATE OF title, body, content_id ON public.posts
FOR EACH ROW
EXECUTE FUNCTION public.enqueue_post_translation_job();

-- 6) Backfill helper for untranslated existing posts
CREATE OR REPLACE FUNCTION public.enqueue_translation_backfill_for_posts(max_rows integer DEFAULT 5000)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  queued_count integer;
BEGIN
  WITH candidate_posts AS (
    SELECT p.id::text AS record_id, p.content_id
    FROM public.posts p
    WHERE p.content_id IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.translation_targets t
        WHERE t.is_active = true
          AND t.language_code <> 'de'
          AND (
            SELECT count(*)
            FROM public.content_translations ct
            WHERE ct.content_id = p.content_id
              AND ct.language = t.language_code
              AND ct.field_name IN ('title', 'body')
          ) < 2
      )
    ORDER BY p.created_at DESC
    LIMIT max_rows
  ), upserted AS (
    INSERT INTO public.translation_jobs (
      content_type,
      record_id,
      content_id,
      status,
      attempts,
      next_retry_at,
      last_error,
      locked_at,
      locked_by
    )
    SELECT
      'post',
      cp.record_id,
      cp.content_id,
      'pending',
      0,
      now(),
      NULL,
      NULL,
      NULL
    FROM candidate_posts cp
    ON CONFLICT (content_type, record_id)
    DO UPDATE
    SET content_id = EXCLUDED.content_id,
        status = 'pending',
        attempts = 0,
        next_retry_at = now(),
        last_error = NULL,
        locked_at = NULL,
        locked_by = NULL,
        updated_at = now()
    RETURNING 1
  )
  SELECT count(*) INTO queued_count FROM upserted;

  RETURN queued_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.enqueue_translation_backfill_for_posts(integer)
TO authenticated, service_role;

COMMENT ON FUNCTION public.enqueue_translation_backfill_for_posts(integer)
IS 'Queues translation jobs for existing posts missing at least one active target translation.';

COMMIT;
