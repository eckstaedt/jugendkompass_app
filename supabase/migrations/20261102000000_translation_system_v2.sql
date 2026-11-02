-- ═══════════════════════════════════════════════════════════════════════════
-- Translation system v2 — fully automatic, stable, provider: Claude (Anthropic)
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Replaces the previous Gemini-based pipeline completely.
--
-- What this migration does
--   1. Cleans up the old pipeline (Gemini cron job, old enqueue triggers,
--      legacy `notify_translate_*` HTTP triggers).
--   2. Hardens `content_translations` (source_hash, status auto/manual).
--   3. Adds `entity_translations` for rows that have no `content_id`
--      (editions, categories).
--   4. Rebuilds the job queue with revision tracking (an edit during a running
--      translation is never lost), stale-lock recovery and SKIP LOCKED claiming.
--   5. Generic triggers on every translatable table: new or changed German text
--      → job is queued → worker is kicked immediately via pg_net.
--   6. Cron safety net (every 2 minutes) that drains the queue.
--   7. Backfill: queues every existing record once, so all existing content is
--      translated into all active languages.
--
-- Source language is ALWAYS German (`de`), stored in the original tables.
-- Target languages are managed in `translation_targets` (is_active = true).
--
-- One-time setup after applying (see TRANSLATION.md):
--   supabase secrets set ANTHROPIC_API_KEY=...
--   supabase functions deploy process-translation-jobs --no-verify-jwt
-- Vault secrets (project URL + random worker secret) are created below.
-- ═══════════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

BEGIN;

-- ───────────────────────────────────────────────────────────────────────────
-- 1) Remove the old pipeline
-- ───────────────────────────────────────────────────────────────────────────

-- Old cron job (contained the Gemini API key in its body!)
DO $$
DECLARE
  j record;
BEGIN
  IF to_regclass('cron.job') IS NOT NULL THEN
    FOR j IN
      SELECT jobid FROM cron.job
      WHERE jobname IN ('process_translation_jobs', 'translation_worker', 'translate_backfill',
                        'process_translation_jobs_en_fastlane',
                        'process_translation_jobs_maintenance')
    LOOP
      PERFORM cron.unschedule(j.jobid);
    END LOOP;
  END IF;
END
$$;

-- Old v1 enqueue triggers
DROP TRIGGER IF EXISTS trg_enqueue_post_translation_job ON public.posts;
DROP TRIGGER IF EXISTS trg_enqueue_message_translation_job ON public.messages;
DROP TRIGGER IF EXISTS trg_enqueue_impulse_translation_job ON public.impulses;
DROP TRIGGER IF EXISTS trg_enqueue_video_translation_job ON public.videos;
DROP TRIGGER IF EXISTS trg_enqueue_verse_translation_job ON public.verse_of_the_day;

-- Legacy HTTP triggers that called the old `translate-content` edge function
DO $$
DECLARE
  t record;
BEGIN
  FOR t IN
    SELECT tg.tgname, c.relname, n.nspname
    FROM pg_trigger tg
    JOIN pg_proc p ON p.oid = tg.tgfoid
    JOIN pg_class c ON c.oid = tg.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE NOT tg.tgisinternal
      AND p.proname IN ('notify_translate_content', 'notify_translate_poll_option')
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', t.tgname, t.nspname, t.relname);
  END LOOP;
END
$$;

DROP FUNCTION IF EXISTS public.enqueue_post_translation_job();
DROP FUNCTION IF EXISTS public.enqueue_message_translation_job();
DROP FUNCTION IF EXISTS public.enqueue_impulse_translation_job();
DROP FUNCTION IF EXISTS public.enqueue_video_translation_job();
DROP FUNCTION IF EXISTS public.enqueue_verse_translation_job();
DROP FUNCTION IF EXISTS public.enqueue_translation_backfill_for_posts(integer);
DROP FUNCTION IF EXISTS public.enqueue_translation_backfill_for_all(integer, text);
DROP FUNCTION IF EXISTS public.enqueue_translation_job(text, text, uuid);

-- ───────────────────────────────────────────────────────────────────────────
-- 2) Target languages
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.translation_targets (
  language_code text PRIMARY KEY,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Must match AppLanguage in lib/core/localization/app_translations.dart
INSERT INTO public.translation_targets (language_code, is_active)
VALUES ('en', true), ('ru', true), ('es', true), ('pl', true), ('tr', true), ('he', true)
ON CONFLICT (language_code) DO UPDATE SET is_active = true, updated_at = now();

ALTER TABLE public.translation_targets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS translation_targets_read ON public.translation_targets;
CREATE POLICY translation_targets_read ON public.translation_targets
  FOR SELECT USING (true);

-- ───────────────────────────────────────────────────────────────────────────
-- 3) content_translations hardening
-- ───────────────────────────────────────────────────────────────────────────
ALTER TABLE public.content_translations ADD COLUMN IF NOT EXISTS source_hash text;
ALTER TABLE public.content_translations ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'auto';
ALTER TABLE public.content_translations ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE public.content_translations ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- Normalise legacy status values so the check constraint can be added.
UPDATE public.content_translations
SET status = 'auto'
WHERE status IS NULL OR status NOT IN ('auto', 'manual');

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'content_translations_status_check'
  ) THEN
    ALTER TABLE public.content_translations
      ADD CONSTRAINT content_translations_status_check CHECK (status IN ('auto', 'manual'));
  END IF;
END
$$;

-- Remove duplicates (keep newest) before enforcing uniqueness.
DELETE FROM public.content_translations a
USING public.content_translations b
WHERE a.content_id = b.content_id
  AND a.language = b.language
  AND a.field_name = b.field_name
  AND a.ctid < b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS content_translations_content_lang_field_uidx
  ON public.content_translations (content_id, language, field_name);

CREATE INDEX IF NOT EXISTS content_translations_lang_content_idx
  ON public.content_translations (language, content_id);

ALTER TABLE public.content_translations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS content_translations_public_read ON public.content_translations;
CREATE POLICY content_translations_public_read ON public.content_translations
  FOR SELECT USING (true);

-- ───────────────────────────────────────────────────────────────────────────
-- 4) entity_translations — for rows without content_id (editions, categories)
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.entity_translations (
  id bigserial PRIMARY KEY,
  entity_type text NOT NULL,
  entity_id text NOT NULL,
  language text NOT NULL,
  field_name text NOT NULL,
  value text NOT NULL,
  source_hash text,
  status text NOT NULL DEFAULT 'auto',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT entity_translations_type_check CHECK (entity_type IN ('edition', 'category')),
  CONSTRAINT entity_translations_status_check CHECK (status IN ('auto', 'manual')),
  CONSTRAINT entity_translations_unique UNIQUE (entity_type, entity_id, language, field_name)
);

CREATE INDEX IF NOT EXISTS entity_translations_lookup_idx
  ON public.entity_translations (entity_type, language, entity_id);

ALTER TABLE public.entity_translations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS entity_translations_public_read ON public.entity_translations;
CREATE POLICY entity_translations_public_read ON public.entity_translations
  FOR SELECT USING (true);
-- Writes: service role (worker) bypasses RLS; admins may edit manually.
DROP POLICY IF EXISTS entity_translations_admin_write ON public.entity_translations;
CREATE POLICY entity_translations_admin_write ON public.entity_translations
  FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Shared updated_at helper
CREATE OR REPLACE FUNCTION public.translation_touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_entity_translations_touch ON public.entity_translations;
CREATE TRIGGER trg_entity_translations_touch
BEFORE UPDATE ON public.entity_translations
FOR EACH ROW EXECUTE FUNCTION public.translation_touch_updated_at();

-- ───────────────────────────────────────────────────────────────────────────
-- 5) Job queue
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.translation_jobs (
  id bigserial PRIMARY KEY,
  content_type text NOT NULL,
  record_id text NOT NULL,
  content_id uuid,
  status text NOT NULL DEFAULT 'pending',
  attempts integer NOT NULL DEFAULT 0,
  next_retry_at timestamptz NOT NULL DEFAULT now(),
  last_error text,
  locked_at timestamptz,
  locked_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT translation_jobs_record_unique UNIQUE (content_type, record_id)
);

ALTER TABLE public.translation_jobs ALTER COLUMN content_id DROP NOT NULL;
ALTER TABLE public.translation_jobs ADD COLUMN IF NOT EXISTS revision bigint NOT NULL DEFAULT 1;
ALTER TABLE public.translation_jobs ADD COLUMN IF NOT EXISTS priority integer NOT NULL DEFAULT 0;
ALTER TABLE public.translation_jobs ADD COLUMN IF NOT EXISTS completed_at timestamptz;

ALTER TABLE public.translation_jobs DROP CONSTRAINT IF EXISTS translation_jobs_content_type_check;
ALTER TABLE public.translation_jobs
  ADD CONSTRAINT translation_jobs_content_type_check
  CHECK (content_type IN ('post', 'message', 'impulse', 'video', 'verse', 'poll', 'edition', 'category'));

ALTER TABLE public.translation_jobs DROP CONSTRAINT IF EXISTS translation_jobs_status_check;
ALTER TABLE public.translation_jobs
  ADD CONSTRAINT translation_jobs_status_check
  CHECK (status IN ('pending', 'processing', 'completed', 'failed'));

CREATE INDEX IF NOT EXISTS translation_jobs_claim_idx
  ON public.translation_jobs (status, next_retry_at, priority DESC, created_at);

DROP TRIGGER IF EXISTS trg_set_translation_jobs_updated_at ON public.translation_jobs;
CREATE TRIGGER trg_set_translation_jobs_updated_at
BEFORE UPDATE ON public.translation_jobs
FOR EACH ROW EXECUTE FUNCTION public.translation_touch_updated_at();

-- Queue is internal: no public access (service role bypasses RLS).
ALTER TABLE public.translation_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS translation_jobs_admin_read ON public.translation_jobs;
CREATE POLICY translation_jobs_admin_read ON public.translation_jobs
  FOR SELECT TO authenticated USING (public.is_admin());

-- Enqueue (idempotent). Every call bumps `revision`, so a worker that is
-- currently translating an older version will not mark the job completed.
CREATE OR REPLACE FUNCTION public.enqueue_translation(
  p_content_type text,
  p_record_id text,
  p_priority integer DEFAULT 10
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_record_id IS NULL OR p_record_id = '' THEN
    RETURN;
  END IF;

  INSERT INTO public.translation_jobs (content_type, record_id, status, attempts, next_retry_at, priority)
  VALUES (p_content_type, p_record_id, 'pending', 0, now(), p_priority)
  ON CONFLICT (content_type, record_id) DO UPDATE
  SET status = 'pending',
      attempts = 0,
      next_retry_at = now(),
      last_error = NULL,
      revision = public.translation_jobs.revision + 1,
      priority = GREATEST(public.translation_jobs.priority, EXCLUDED.priority),
      -- keep the lock if a worker is busy; it will see the new revision
      locked_at = CASE WHEN public.translation_jobs.status = 'processing'
                       THEN public.translation_jobs.locked_at ELSE NULL END,
      locked_by = CASE WHEN public.translation_jobs.status = 'processing'
                       THEN public.translation_jobs.locked_by ELSE NULL END;
END;
$$;

-- Claim a batch atomically. Stale locks (> 10 min) are reclaimed.
CREATE OR REPLACE FUNCTION public.claim_translation_jobs(
  p_batch_size integer DEFAULT 5,
  p_worker text DEFAULT 'worker'
)
RETURNS TABLE (id bigint, content_type text, record_id text, revision bigint, attempts integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH candidates AS (
    SELECT j.id
    FROM public.translation_jobs j
    WHERE (
        j.status = 'pending' AND j.next_retry_at <= now()
        AND (j.locked_at IS NULL OR j.locked_at < now() - interval '10 minutes')
      )
      OR (j.status = 'processing' AND j.locked_at < now() - interval '10 minutes')
    ORDER BY j.priority DESC, j.created_at
    LIMIT GREATEST(1, LEAST(p_batch_size, 50))
    FOR UPDATE SKIP LOCKED
  )
  UPDATE public.translation_jobs j
  SET status = 'processing',
      locked_at = now(),
      locked_by = p_worker
  FROM candidates c
  WHERE j.id = c.id
  RETURNING j.id, j.content_type, j.record_id, j.revision, j.attempts;
END;
$$;

-- Finish a job. Only completes if no newer revision arrived meanwhile;
-- otherwise the job goes back to pending and is picked up again.
CREATE OR REPLACE FUNCTION public.finish_translation_job(
  p_job_id bigint,
  p_revision bigint,
  p_success boolean,
  p_error text DEFAULT NULL,
  p_max_attempts integer DEFAULT 8
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job public.translation_jobs%ROWTYPE;
  v_attempts integer;
BEGIN
  SELECT * INTO v_job FROM public.translation_jobs WHERE id = p_job_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN 'missing';
  END IF;

  IF v_job.revision <> p_revision THEN
    UPDATE public.translation_jobs
    SET status = 'pending', locked_at = NULL, locked_by = NULL, next_retry_at = now()
    WHERE id = p_job_id;
    RETURN 'requeued';
  END IF;

  IF p_success THEN
    UPDATE public.translation_jobs
    SET status = 'completed', last_error = NULL, locked_at = NULL, locked_by = NULL,
        completed_at = now()
    WHERE id = p_job_id;
    RETURN 'completed';
  END IF;

  v_attempts := v_job.attempts + 1;
  UPDATE public.translation_jobs
  SET attempts = v_attempts,
      status = CASE WHEN v_attempts >= p_max_attempts THEN 'failed' ELSE 'pending' END,
      -- exponential backoff: 1, 2, 4, ... max 60 minutes
      next_retry_at = now() + make_interval(mins => LEAST(60, power(2, LEAST(v_attempts - 1, 6))::int)),
      last_error = left(coalesce(p_error, 'unknown error'), 2000),
      locked_at = NULL,
      locked_by = NULL
  WHERE id = p_job_id;

  RETURN CASE WHEN v_attempts >= p_max_attempts THEN 'failed' ELSE 'retry' END;
END;
$$;

-- Re-queue failed jobs (e.g. after fixing an API key).
CREATE OR REPLACE FUNCTION public.retry_failed_translations()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  n integer;
BEGIN
  UPDATE public.translation_jobs
  SET status = 'pending', attempts = 0, next_retry_at = now(), last_error = NULL,
      revision = revision + 1
  WHERE status = 'failed';
  GET DIAGNOSTICS n = ROW_COUNT;
  PERFORM public.kick_translation_worker();
  RETURN n;
END;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- 6) Kick the worker immediately (async HTTP via pg_net, never blocks writes)
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.kick_translation_worker()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_url text;
  v_secret text;
BEGIN
  BEGIN
    SELECT decrypted_secret INTO v_url
    FROM vault.decrypted_secrets WHERE name = 'translation_project_url' LIMIT 1;
    SELECT decrypted_secret INTO v_secret
    FROM vault.decrypted_secrets WHERE name = 'translation_worker_secret' LIMIT 1;

    IF v_url IS NULL OR v_secret IS NULL THEN
      RETURN; -- not configured yet; cron + manual invoke still work
    END IF;

    PERFORM net.http_post(
      url := rtrim(v_url, '/') || '/functions/v1/process-translation-jobs',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-translation-secret', v_secret
      ),
      body := jsonb_build_object('source', 'trigger'),
      timeout_milliseconds := 5000
    );
  EXCEPTION WHEN OTHERS THEN
    -- Never let translation plumbing break a content insert/update.
    RAISE WARNING 'kick_translation_worker failed: %', SQLERRM;
  END;
END;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- 7) Generic enqueue trigger
--    TG_ARGV[0] = job type, TG_ARGV[1..] = translatable source columns
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.trg_enqueue_translation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_type text := TG_ARGV[0];
  v_new jsonb := to_jsonb(NEW);
  v_old jsonb;
  v_changed boolean := (TG_OP = 'INSERT');
  v_record_id text;
  i integer;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    v_old := to_jsonb(OLD);
    FOR i IN 1 .. TG_NARGS - 1 LOOP
      IF (v_new -> TG_ARGV[i]) IS DISTINCT FROM (v_old -> TG_ARGV[i]) THEN
        v_changed := true;
      END IF;
    END LOOP;
    IF (v_new -> 'content_id') IS DISTINCT FROM (v_old -> 'content_id') THEN
      v_changed := true;
    END IF;
  END IF;

  IF NOT v_changed THEN
    RETURN NEW;
  END IF;

  IF v_type = 'poll_option' THEN
    v_type := 'poll';
    v_record_id := v_new ->> 'poll_id';
  ELSE
    v_record_id := v_new ->> 'id';
  END IF;

  PERFORM public.enqueue_translation(v_type, v_record_id, 10);
  PERFORM public.kick_translation_worker();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_translate_posts ON public.posts;
CREATE TRIGGER trg_translate_posts
AFTER INSERT OR UPDATE ON public.posts
FOR EACH ROW EXECUTE FUNCTION public.trg_enqueue_translation('post', 'title', 'body');

DROP TRIGGER IF EXISTS trg_translate_messages ON public.messages;
CREATE TRIGGER trg_translate_messages
AFTER INSERT OR UPDATE ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.trg_enqueue_translation('message', 'title', 'message');

DROP TRIGGER IF EXISTS trg_translate_impulses ON public.impulses;
CREATE TRIGGER trg_translate_impulses
AFTER INSERT OR UPDATE ON public.impulses
FOR EACH ROW EXECUTE FUNCTION public.trg_enqueue_translation('impulse', 'title', 'impulse_text');

DROP TRIGGER IF EXISTS trg_translate_videos ON public.videos;
CREATE TRIGGER trg_translate_videos
AFTER INSERT OR UPDATE ON public.videos
FOR EACH ROW EXECUTE FUNCTION public.trg_enqueue_translation('video', 'title', 'description');

DROP TRIGGER IF EXISTS trg_translate_verses ON public.verse_of_the_day;
CREATE TRIGGER trg_translate_verses
AFTER INSERT OR UPDATE ON public.verse_of_the_day
FOR EACH ROW EXECUTE FUNCTION public.trg_enqueue_translation('verse', 'verse', 'reference');

DROP TRIGGER IF EXISTS trg_translate_polls ON public.polls;
CREATE TRIGGER trg_translate_polls
AFTER INSERT OR UPDATE ON public.polls
FOR EACH ROW EXECUTE FUNCTION public.trg_enqueue_translation('poll', 'question');

DROP TRIGGER IF EXISTS trg_translate_poll_options ON public.poll_options;
CREATE TRIGGER trg_translate_poll_options
AFTER INSERT OR UPDATE OF option_text, poll_id ON public.poll_options
FOR EACH ROW EXECUTE FUNCTION public.trg_enqueue_translation('poll_option', 'option_text');

DROP TRIGGER IF EXISTS trg_translate_editions ON public.editions;
CREATE TRIGGER trg_translate_editions
AFTER INSERT OR UPDATE ON public.editions
FOR EACH ROW EXECUTE FUNCTION public.trg_enqueue_translation('edition', 'name', 'title', 'body');

DROP TRIGGER IF EXISTS trg_translate_categories ON public.categories;
CREATE TRIGGER trg_translate_categories
AFTER INSERT OR UPDATE ON public.categories
FOR EACH ROW EXECUTE FUNCTION public.trg_enqueue_translation('category', 'name');

-- Clean up translations of deleted editions / categories (content rows are
-- cleaned via FK on content_translations).
CREATE OR REPLACE FUNCTION public.trg_cleanup_entity_translations()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.entity_translations
  WHERE entity_type = TG_ARGV[0] AND entity_id = OLD.id::text;
  DELETE FROM public.translation_jobs
  WHERE content_type = TG_ARGV[0] AND record_id = OLD.id::text;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_cleanup_edition_translations ON public.editions;
CREATE TRIGGER trg_cleanup_edition_translations
AFTER DELETE ON public.editions
FOR EACH ROW EXECUTE FUNCTION public.trg_cleanup_entity_translations('edition');

DROP TRIGGER IF EXISTS trg_cleanup_category_translations ON public.categories;
CREATE TRIGGER trg_cleanup_category_translations
AFTER DELETE ON public.categories
FOR EACH ROW EXECUTE FUNCTION public.trg_cleanup_entity_translations('category');

-- ───────────────────────────────────────────────────────────────────────────
-- 8) Backfill: queue every existing record. The worker skips fields whose
--    translation is already up to date (same source_hash), so re-running this
--    is cheap and safe.
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.enqueue_translation_backfill()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  n integer := 0;
  added integer;
BEGIN
  -- newest content first, so what users see first is translated first
  INSERT INTO public.translation_jobs (content_type, record_id, status, priority, created_at)
  SELECT t.kind, t.rid, 'pending', 0, now() + (t.rn * interval '1 millisecond')
  FROM (
    SELECT 'verse'::text AS kind, id::text AS rid, row_number() OVER (ORDER BY abs(date - current_date), date DESC) AS rn FROM public.verse_of_the_day
    UNION ALL SELECT 'impulse', id::text, row_number() OVER (ORDER BY abs(date - current_date), date DESC) FROM public.impulses
    UNION ALL SELECT 'post', id::text, row_number() OVER (ORDER BY created_at DESC) FROM public.posts
    UNION ALL SELECT 'message', id::text, row_number() OVER (ORDER BY created_at DESC) FROM public.messages
    UNION ALL SELECT 'video', id::text, row_number() OVER (ORDER BY created_at DESC) FROM public.videos
    UNION ALL SELECT 'poll', id::text, row_number() OVER (ORDER BY created_at DESC) FROM public.polls
    UNION ALL SELECT 'edition', id::text, row_number() OVER (ORDER BY published_at DESC NULLS LAST) FROM public.editions
    UNION ALL SELECT 'category', id::text, row_number() OVER (ORDER BY name) FROM public.categories
  ) t
  ON CONFLICT (content_type, record_id) DO UPDATE
  SET status = 'pending',
      attempts = 0,
      next_retry_at = now(),
      last_error = NULL,
      revision = public.translation_jobs.revision + 1
  WHERE public.translation_jobs.status <> 'processing';

  GET DIAGNOSTICS added = ROW_COUNT;
  n := n + added;

  PERFORM public.kick_translation_worker();
  RETURN n;
END;
$$;

REVOKE ALL ON FUNCTION public.enqueue_translation(text, text, integer) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.claim_translation_jobs(integer, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.finish_translation_job(bigint, bigint, boolean, text, integer) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.kick_translation_worker() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.enqueue_translation_backfill() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.retry_failed_translations() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.enqueue_translation(text, text, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.claim_translation_jobs(integer, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.finish_translation_job(bigint, bigint, boolean, text, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.kick_translation_worker() TO service_role;
GRANT EXECUTE ON FUNCTION public.enqueue_translation_backfill() TO service_role;
GRANT EXECUTE ON FUNCTION public.retry_failed_translations() TO service_role;

-- ───────────────────────────────────────────────────────────────────────────
-- 9) Monitoring view (admins / SQL editor)
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.translation_queue_status
WITH (security_invoker = true) AS
SELECT
  content_type,
  count(*) FILTER (WHERE status = 'pending')    AS pending,
  count(*) FILTER (WHERE status = 'processing') AS processing,
  count(*) FILTER (WHERE status = 'completed')  AS completed,
  count(*) FILTER (WHERE status = 'failed')     AS failed,
  max(completed_at)                             AS last_completed_at,
  (array_agg(last_error ORDER BY updated_at DESC) FILTER (WHERE last_error IS NOT NULL))[1] AS last_error
FROM public.translation_jobs
GROUP BY content_type;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────
-- 10) Cron safety net: drain the queue every 2 minutes (outside the tx so a
--     missing pg_cron never rolls back the schema changes above).
-- ───────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF to_regclass('cron.job') IS NOT NULL THEN
    PERFORM cron.unschedule(jobid) FROM cron.job WHERE jobname = 'translation_worker_v2';
    PERFORM cron.schedule(
      'translation_worker_v2',
      '*/2 * * * *',
      $cron$
        SELECT public.kick_translation_worker()
        WHERE EXISTS (
          SELECT 1 FROM public.translation_jobs
          WHERE (status = 'pending' AND next_retry_at <= now())
             OR (status = 'processing' AND locked_at < now() - interval '10 minutes')
        );
      $cron$
    );
  END IF;
END
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- 11) Vault secrets: created automatically (no manual setup needed).
--     The worker secret is random; the edge function reads it via
--     get_translation_worker_secret() with the service role.
-- ───────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF to_regclass('vault.secrets') IS NULL THEN
    RAISE WARNING 'Supabase Vault not available – translation worker will only run via manual invoke';
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'translation_project_url') THEN
    PERFORM vault.create_secret(
      'https://vdcdibvclaulqxfjyzpq.supabase.co',
      'translation_project_url',
      'Base URL used by kick_translation_worker()'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'translation_worker_secret') THEN
    PERFORM vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'translation_worker_secret',
      'Shared secret between database and process-translation-jobs'
    );
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Could not create vault secrets automatically: %', SQLERRM;
END
$$;

CREATE OR REPLACE FUNCTION public.get_translation_worker_secret()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT decrypted_secret FROM vault.decrypted_secrets
  WHERE name = 'translation_worker_secret' LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_translation_worker_secret() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_translation_worker_secret() TO service_role;

-- Queue ALL existing content for translation into all active languages.
SELECT public.enqueue_translation_backfill();
