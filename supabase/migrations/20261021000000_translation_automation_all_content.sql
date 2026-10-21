-- Extend translation automation to all content types used in the app
-- Covers: posts, messages, impulses, videos, verse_of_the_day

BEGIN;

-- 1) Expand allowed content types in translation_jobs
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'translation_jobs'
      AND constraint_name = 'translation_jobs_content_type_check'
  ) THEN
    ALTER TABLE public.translation_jobs
      DROP CONSTRAINT translation_jobs_content_type_check;
  END IF;

  ALTER TABLE public.translation_jobs
    ADD CONSTRAINT translation_jobs_content_type_check
    CHECK (content_type IN ('post', 'message', 'impulse', 'video', 'verse'));
END
$$;

CREATE INDEX IF NOT EXISTS translation_jobs_type_status_retry_idx
  ON public.translation_jobs (content_type, status, next_retry_at, created_at);

-- 2) Shared enqueue helper
CREATE OR REPLACE FUNCTION public.enqueue_translation_job(
  p_content_type text,
  p_record_id text,
  p_content_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_content_id IS NULL THEN
    RETURN;
  END IF;

  IF p_content_type NOT IN ('post', 'message', 'impulse', 'video', 'verse') THEN
    RETURN;
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
    p_content_type,
    p_record_id,
    p_content_id,
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
END;
$$;

-- 3) Type-specific trigger functions
CREATE OR REPLACE FUNCTION public.enqueue_post_translation_job()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM public.enqueue_translation_job('post', NEW.id::text, NEW.content_id);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.enqueue_message_translation_job()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM public.enqueue_translation_job('message', NEW.id::text, NEW.content_id);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.enqueue_impulse_translation_job()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM public.enqueue_translation_job('impulse', NEW.id::text, NEW.content_id);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.enqueue_video_translation_job()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM public.enqueue_translation_job('video', NEW.id::text, NEW.content_id);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.enqueue_verse_translation_job()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM public.enqueue_translation_job('verse', NEW.id::text, NEW.content_id);
  RETURN NEW;
END;
$$;

-- 4) Triggers on content tables for new/updated records
DROP TRIGGER IF EXISTS trg_enqueue_post_translation_job ON public.posts;
CREATE TRIGGER trg_enqueue_post_translation_job
AFTER INSERT OR UPDATE OF title, body, content_id ON public.posts
FOR EACH ROW
EXECUTE FUNCTION public.enqueue_post_translation_job();

DROP TRIGGER IF EXISTS trg_enqueue_message_translation_job ON public.messages;
CREATE TRIGGER trg_enqueue_message_translation_job
AFTER INSERT OR UPDATE OF title, message, content_id ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.enqueue_message_translation_job();

DROP TRIGGER IF EXISTS trg_enqueue_impulse_translation_job ON public.impulses;
CREATE TRIGGER trg_enqueue_impulse_translation_job
AFTER INSERT OR UPDATE OF title, impulse_text, content_id ON public.impulses
FOR EACH ROW
EXECUTE FUNCTION public.enqueue_impulse_translation_job();

DROP TRIGGER IF EXISTS trg_enqueue_video_translation_job ON public.videos;
CREATE TRIGGER trg_enqueue_video_translation_job
AFTER INSERT OR UPDATE OF title, description, content_id ON public.videos
FOR EACH ROW
EXECUTE FUNCTION public.enqueue_video_translation_job();

DROP TRIGGER IF EXISTS trg_enqueue_verse_translation_job ON public.verse_of_the_day;
CREATE TRIGGER trg_enqueue_verse_translation_job
AFTER INSERT OR UPDATE OF verse, reference, content_id ON public.verse_of_the_day
FOR EACH ROW
EXECUTE FUNCTION public.enqueue_verse_translation_job();

-- 5) Generic backfill function for all content types
CREATE OR REPLACE FUNCTION public.enqueue_translation_backfill_for_all(
  max_rows_per_type integer DEFAULT 5000,
  target_language text DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  queued_total integer := 0;
  added_count integer := 0;
BEGIN
  -- posts (title, body)
  WITH candidate_rows AS (
    SELECT p.id::text AS record_id, p.content_id
    FROM public.posts p
    WHERE p.content_id IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.translation_targets t
        WHERE t.is_active = true
          AND t.language_code <> 'de'
          AND (target_language IS NULL OR t.language_code = target_language)
          AND (
            SELECT count(*)
            FROM public.content_translations ct
            WHERE ct.content_id = p.content_id
              AND ct.language = t.language_code
              AND ct.field_name IN ('title', 'body')
          ) < 2
      )
    ORDER BY p.created_at DESC
    LIMIT max_rows_per_type
  ), upserted AS (
    INSERT INTO public.translation_jobs (
      content_type, record_id, content_id, status, attempts, next_retry_at,
      last_error, locked_at, locked_by
    )
    SELECT 'post', c.record_id, c.content_id, 'pending', 0, now(), NULL, NULL, NULL
    FROM candidate_rows c
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
  SELECT count(*) INTO added_count FROM upserted;

  queued_total := queued_total + added_count;

  -- messages (title, message)
  WITH candidate_rows AS (
    SELECT m.id::text AS record_id, m.content_id
    FROM public.messages m
    WHERE m.content_id IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.translation_targets t
        WHERE t.is_active = true
          AND t.language_code <> 'de'
          AND (target_language IS NULL OR t.language_code = target_language)
          AND (
            SELECT count(*)
            FROM public.content_translations ct
            WHERE ct.content_id = m.content_id
              AND ct.language = t.language_code
              AND ct.field_name IN ('title', 'message')
          ) < 2
      )
    ORDER BY m.created_at DESC
    LIMIT max_rows_per_type
  ), upserted AS (
    INSERT INTO public.translation_jobs (
      content_type, record_id, content_id, status, attempts, next_retry_at,
      last_error, locked_at, locked_by
    )
    SELECT 'message', c.record_id, c.content_id, 'pending', 0, now(), NULL, NULL, NULL
    FROM candidate_rows c
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
  SELECT count(*) INTO added_count FROM upserted;

  queued_total := queued_total + added_count;

  -- impulses (title, impulse_text)
  WITH candidate_rows AS (
    SELECT i.id::text AS record_id, i.content_id
    FROM public.impulses i
    WHERE i.content_id IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.translation_targets t
        WHERE t.is_active = true
          AND t.language_code <> 'de'
          AND (target_language IS NULL OR t.language_code = target_language)
          AND (
            SELECT count(*)
            FROM public.content_translations ct
            WHERE ct.content_id = i.content_id
              AND ct.language = t.language_code
              AND ct.field_name IN ('title', 'impulse_text')
          ) < 2
      )
    ORDER BY i.created_at DESC
    LIMIT max_rows_per_type
  ), upserted AS (
    INSERT INTO public.translation_jobs (
      content_type, record_id, content_id, status, attempts, next_retry_at,
      last_error, locked_at, locked_by
    )
    SELECT 'impulse', c.record_id, c.content_id, 'pending', 0, now(), NULL, NULL, NULL
    FROM candidate_rows c
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
  SELECT count(*) INTO added_count FROM upserted;

  queued_total := queued_total + added_count;

  -- videos (title, description)
  WITH candidate_rows AS (
    SELECT v.id::text AS record_id, v.content_id
    FROM public.videos v
    WHERE v.content_id IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.translation_targets t
        WHERE t.is_active = true
          AND t.language_code <> 'de'
          AND (target_language IS NULL OR t.language_code = target_language)
          AND (
            SELECT count(*)
            FROM public.content_translations ct
            WHERE ct.content_id = v.content_id
              AND ct.language = t.language_code
              AND ct.field_name IN ('title', 'description')
          ) < 2
      )
    ORDER BY v.created_at DESC
    LIMIT max_rows_per_type
  ), upserted AS (
    INSERT INTO public.translation_jobs (
      content_type, record_id, content_id, status, attempts, next_retry_at,
      last_error, locked_at, locked_by
    )
    SELECT 'video', c.record_id, c.content_id, 'pending', 0, now(), NULL, NULL, NULL
    FROM candidate_rows c
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
  SELECT count(*) INTO added_count FROM upserted;

  queued_total := queued_total + added_count;

  -- verses (verse, reference)
  WITH candidate_rows AS (
    SELECT v.id::text AS record_id, v.content_id
    FROM public.verse_of_the_day v
    WHERE v.content_id IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.translation_targets t
        WHERE t.is_active = true
          AND t.language_code <> 'de'
          AND (target_language IS NULL OR t.language_code = target_language)
          AND (
            SELECT count(*)
            FROM public.content_translations ct
            WHERE ct.content_id = v.content_id
              AND ct.language = t.language_code
              AND ct.field_name IN ('verse', 'reference')
          ) < 2
      )
    ORDER BY v.date DESC, v.created_at DESC
    LIMIT max_rows_per_type
  ), upserted AS (
    INSERT INTO public.translation_jobs (
      content_type, record_id, content_id, status, attempts, next_retry_at,
      last_error, locked_at, locked_by
    )
    SELECT 'verse', c.record_id, c.content_id, 'pending', 0, now(), NULL, NULL, NULL
    FROM candidate_rows c
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
  SELECT count(*) INTO added_count FROM upserted;

  queued_total := queued_total + added_count;

  RETURN queued_total;
END;
$$;

GRANT EXECUTE ON FUNCTION public.enqueue_translation_backfill_for_all(integer, text)
TO authenticated, service_role;

COMMENT ON FUNCTION public.enqueue_translation_backfill_for_all(integer, text)
IS 'Queues translation jobs for all supported content types with missing translations. Optional target_language limits queueing to one language (e.g. en).';

COMMIT;
