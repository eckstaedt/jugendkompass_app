-- ═══════════════════════════════════════════════════════════════════════════
-- Translation panel (web admin UI, see translation-panel/)
--   * translation_events: log of every job status change (trigger-based)
--   * audio_translations: dubbed audio per language for an original audio
--   * admin RPCs: overview, retry, re-run per content type, worker runs
-- All RPCs are SECURITY DEFINER and check public.users.role = 'admin'.
-- ═══════════════════════════════════════════════════════════════════════════

BEGIN;

CREATE OR REPLACE FUNCTION public.tp_is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin');
$$;

CREATE OR REPLACE FUNCTION public.tp_require_admin()
RETURNS void
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.tp_is_admin() THEN
    RAISE EXCEPTION 'admin only' USING ERRCODE = '42501';
  END IF;
END;
$$;

-- Admins may read the queue (existing policy used is_admin() which reads auth.users.role)
DROP POLICY IF EXISTS translation_jobs_panel_read ON public.translation_jobs;
CREATE POLICY translation_jobs_panel_read ON public.translation_jobs
  FOR SELECT TO authenticated USING (public.tp_is_admin());

-- ───────────────────────────────────────────────────────────────────────────
-- Event log
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.translation_events (
  id bigserial PRIMARY KEY,
  job_id bigint,
  content_type text,
  record_id text,
  event text NOT NULL,           -- queued | processing | completed | failed | retry | requeued | admin
  status text,
  attempts integer,
  message text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS translation_events_created_idx ON public.translation_events (created_at DESC);
CREATE INDEX IF NOT EXISTS translation_events_record_idx ON public.translation_events (content_type, record_id, created_at DESC);

ALTER TABLE public.translation_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS translation_events_admin_read ON public.translation_events;
CREATE POLICY translation_events_admin_read ON public.translation_events
  FOR SELECT TO authenticated USING (public.tp_is_admin());

CREATE OR REPLACE FUNCTION public.trg_log_translation_job()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_event := 'queued';
  ELSIF NEW.status IS DISTINCT FROM OLD.status THEN
    v_event := CASE
      WHEN NEW.status = 'pending' AND OLD.status = 'processing' AND NEW.last_error IS NOT NULL
           AND NEW.attempts > OLD.attempts THEN 'retry'
      WHEN NEW.status = 'pending' AND OLD.status = 'processing' THEN 'requeued'
      WHEN NEW.status = 'pending' THEN 'queued'
      ELSE NEW.status
    END;
  ELSIF NEW.revision IS DISTINCT FROM OLD.revision THEN
    v_event := 'queued';
  ELSE
    RETURN NEW;
  END IF;

  INSERT INTO public.translation_events (job_id, content_type, record_id, event, status, attempts, message)
  VALUES (NEW.id, NEW.content_type, NEW.record_id, v_event, NEW.status, NEW.attempts,
          CASE WHEN v_event IN ('failed', 'retry') THEN left(NEW.last_error, 2000)
               WHEN v_event = 'processing' THEN NEW.locked_by END);
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW; -- logging must never break the queue
END;
$$;

DROP TRIGGER IF EXISTS trg_log_translation_job ON public.translation_jobs;
CREATE TRIGGER trg_log_translation_job
AFTER INSERT OR UPDATE ON public.translation_jobs
FOR EACH ROW EXECUTE FUNCTION public.trg_log_translation_job();

CREATE OR REPLACE FUNCTION public.tp_log(p_message text, p_content_type text DEFAULT NULL)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  INSERT INTO public.translation_events (content_type, event, message)
  VALUES (p_content_type, 'admin', p_message);
$$;
REVOKE ALL ON FUNCTION public.tp_log(text, text) FROM PUBLIC, anon, authenticated;

-- keep the log small (daily cleanup, 21 days)
DO $$
DECLARE j record;
BEGIN
  FOR j IN SELECT jobid FROM cron.job WHERE jobname = 'translation_events_cleanup' LOOP
    PERFORM cron.unschedule(j.jobid);
  END LOOP;
  PERFORM cron.schedule('translation_events_cleanup', '17 3 * * *',
    $c$DELETE FROM public.translation_events WHERE created_at < now() - interval '21 days'$c$);
END
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- Audio translations (dubbed audio per language)
-- ───────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.audio_translations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  audio_id uuid NOT NULL REFERENCES public.audios(id) ON DELETE CASCADE,
  language text NOT NULL,
  url text NOT NULL,
  storage_path text,
  file_name text,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT audio_translations_unique UNIQUE (audio_id, language),
  CONSTRAINT audio_translations_lang_check CHECK (language <> 'de')
);
CREATE INDEX IF NOT EXISTS audio_translations_lang_idx ON public.audio_translations (language, audio_id);

ALTER TABLE public.audio_translations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS audio_translations_public_read ON public.audio_translations;
CREATE POLICY audio_translations_public_read ON public.audio_translations
  FOR SELECT USING (true);
DROP POLICY IF EXISTS audio_translations_admin_write ON public.audio_translations;
CREATE POLICY audio_translations_admin_write ON public.audio_translations
  FOR ALL TO authenticated USING (public.tp_is_admin()) WITH CHECK (public.tp_is_admin());

DROP TRIGGER IF EXISTS trg_audio_translations_touch ON public.audio_translations;
CREATE TRIGGER trg_audio_translations_touch
BEFORE UPDATE ON public.audio_translations
FOR EACH ROW EXECUTE FUNCTION public.translation_touch_updated_at();

-- ───────────────────────────────────────────────────────────────────────────
-- Helpers: content_id per content type
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.tp_content_ids(p_type text)
RETURNS TABLE (record_id text, content_id uuid)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY EXECUTE format('SELECT id::text, content_id FROM public.%I',
    CASE p_type
      WHEN 'post' THEN 'posts' WHEN 'message' THEN 'messages' WHEN 'impulse' THEN 'impulses'
      WHEN 'video' THEN 'videos' WHEN 'verse' THEN 'verse_of_the_day' WHEN 'poll' THEN 'polls'
      ELSE NULL END);
END;
$$;
REVOKE ALL ON FUNCTION public.tp_content_ids(text) FROM PUBLIC, anon, authenticated;

-- ───────────────────────────────────────────────────────────────────────────
-- Overview
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.tp_overview()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_types text[] := ARRAY['post','message','impulse','video','verse','poll','edition','category'];
  v_t text;
  v_coverage jsonb := '[]'::jsonb;
  v_total bigint;
  v_lang jsonb;
BEGIN
  PERFORM public.tp_require_admin();

  FOREACH v_t IN ARRAY v_types LOOP
    IF v_t IN ('edition', 'category') THEN
      EXECUTE format('SELECT count(*) FROM public.%I', CASE v_t WHEN 'edition' THEN 'editions' ELSE 'categories' END)
        INTO v_total;
      SELECT coalesce(jsonb_object_agg(language, n), '{}'::jsonb) INTO v_lang
      FROM (SELECT language, count(DISTINCT entity_id) n FROM public.entity_translations
            WHERE entity_type = v_t GROUP BY language) x;
    ELSE
      SELECT count(*) INTO v_total FROM public.tp_content_ids(v_t);
      SELECT coalesce(jsonb_object_agg(language, n), '{}'::jsonb) INTO v_lang
      FROM (SELECT ct.language, count(DISTINCT ct.content_id) n
            FROM public.content_translations ct
            JOIN public.tp_content_ids(v_t) s ON s.content_id = ct.content_id
            GROUP BY ct.language) x;
    END IF;
    v_coverage := v_coverage || jsonb_build_object('content_type', v_t, 'total', v_total, 'languages', v_lang);
  END LOOP;

  RETURN jsonb_build_object(
    'now', now(),
    'languages', (SELECT coalesce(jsonb_agg(jsonb_build_object('code', language_code, 'active', is_active) ORDER BY language_code), '[]')
                  FROM public.translation_targets),
    'queue', (SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.content_type), '[]') FROM public.translation_queue_status q),
    'coverage', v_coverage,
    'credit_error', EXISTS (
      SELECT 1 FROM public.translation_jobs
      WHERE last_error ILIKE '%credit balance%' AND updated_at > now() - interval '3 days'
        AND status IN ('failed', 'pending')),
    'auth_error', EXISTS (
      SELECT 1 FROM public.translation_jobs
      WHERE (last_error ILIKE '%authentication_error%' OR last_error ILIKE '%invalid x-api-key%'
             OR last_error ILIKE '%ANTHROPIC_API_KEY%')
        AND status IN ('failed', 'pending')),
    'last_completed_at', (SELECT max(completed_at) FROM public.translation_jobs),
    'last_activity_at', (SELECT max(updated_at) FROM public.translation_jobs),
    'processing_now', (SELECT count(*) FROM public.translation_jobs WHERE status = 'processing'),
    'next_retry_at', (SELECT min(next_retry_at) FROM public.translation_jobs WHERE status = 'pending'),
    'completed_24h', (SELECT count(*) FROM public.translation_jobs WHERE completed_at > now() - interval '24 hours'),
    'audio', jsonb_build_object(
      'total', (SELECT count(*) FROM public.audios),
      'languages', (SELECT coalesce(jsonb_object_agg(language, n), '{}') FROM
                     (SELECT language, count(*) n FROM public.audio_translations GROUP BY language) a))
  );
END;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- Actions
-- ───────────────────────────────────────────────────────────────────────────

-- Retry failed jobs (optionally only one content type)
CREATE OR REPLACE FUNCTION public.tp_retry_failed(p_content_type text DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE n integer;
BEGIN
  PERFORM public.tp_require_admin();
  UPDATE public.translation_jobs
  SET status = 'pending', attempts = 0, next_retry_at = now(), last_error = NULL,
      revision = revision + 1, locked_at = NULL, locked_by = NULL
  WHERE status = 'failed' AND (p_content_type IS NULL OR content_type = p_content_type);
  GET DIAGNOSTICS n = ROW_COUNT;
  PERFORM public.tp_log(format('Fehlgeschlagene neu gestartet: %s Jobs', n), p_content_type);
  PERFORM public.kick_translation_worker();
  RETURN n;
END;
$$;

-- Also pull pending jobs that wait for backoff to "now"
CREATE OR REPLACE FUNCTION public.tp_run_now()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE n integer;
BEGIN
  PERFORM public.tp_require_admin();
  UPDATE public.translation_jobs SET next_retry_at = now()
  WHERE status = 'pending' AND next_retry_at > now();
  GET DIAGNOSTICS n = ROW_COUNT;
  PERFORM public.tp_log(format('Worker manuell angestoßen (%s wartende Jobs vorgezogen)', n));
  PERFORM public.kick_translation_worker();
  RETURN n;
END;
$$;

-- Re-run a whole content type. p_force = true invalidates existing automatic
-- translations so they are translated again (manual ones are kept).
CREATE OR REPLACE FUNCTION public.tp_rerun_type(p_content_type text, p_force boolean DEFAULT false)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  n integer;
  v_table text;
BEGIN
  PERFORM public.tp_require_admin();
  v_table := CASE p_content_type
    WHEN 'post' THEN 'posts' WHEN 'message' THEN 'messages' WHEN 'impulse' THEN 'impulses'
    WHEN 'video' THEN 'videos' WHEN 'verse' THEN 'verse_of_the_day' WHEN 'poll' THEN 'polls'
    WHEN 'edition' THEN 'editions' WHEN 'category' THEN 'categories' END;
  IF v_table IS NULL THEN
    RAISE EXCEPTION 'unknown content type %', p_content_type;
  END IF;

  IF p_force THEN
    IF p_content_type IN ('edition', 'category') THEN
      UPDATE public.entity_translations SET source_hash = NULL
      WHERE entity_type = p_content_type AND status = 'auto';
    ELSE
      UPDATE public.content_translations ct SET source_hash = NULL
      FROM public.tp_content_ids(p_content_type) s
      WHERE s.content_id = ct.content_id AND ct.status = 'auto';
    END IF;
  END IF;

  EXECUTE format($q$
    INSERT INTO public.translation_jobs (content_type, record_id, status, priority)
    SELECT %L, id::text, 'pending', 5 FROM public.%I
    ON CONFLICT (content_type, record_id) DO UPDATE
    SET status = 'pending', attempts = 0, next_retry_at = now(), last_error = NULL,
        priority = GREATEST(public.translation_jobs.priority, 5),
        revision = public.translation_jobs.revision + 1
    WHERE public.translation_jobs.status <> 'processing'$q$, p_content_type, v_table);
  GET DIAGNOSTICS n = ROW_COUNT;

  PERFORM public.tp_log(format('%s neu gestartet%s: %s Jobs', p_content_type,
    CASE WHEN p_force THEN ' (komplett neu übersetzen)' ELSE '' END, n), p_content_type);
  PERFORM public.kick_translation_worker();
  RETURN n;
END;
$$;

-- Re-run a single record
CREATE OR REPLACE FUNCTION public.tp_rerun_record(p_content_type text, p_record_id text, p_force boolean DEFAULT false)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_cid uuid;
BEGIN
  PERFORM public.tp_require_admin();
  IF p_force THEN
    IF p_content_type IN ('edition', 'category') THEN
      UPDATE public.entity_translations SET source_hash = NULL
      WHERE entity_type = p_content_type AND entity_id = p_record_id AND status = 'auto';
    ELSE
      SELECT s.content_id INTO v_cid FROM public.tp_content_ids(p_content_type) s WHERE s.record_id = p_record_id;
      UPDATE public.content_translations SET source_hash = NULL
      WHERE content_id = v_cid AND status = 'auto';
    END IF;
  END IF;
  PERFORM public.enqueue_translation(p_content_type, p_record_id, 20);
  PERFORM public.tp_log(format('Einzeln neu gestartet: %s/%s', p_content_type, p_record_id), p_content_type);
  PERFORM public.kick_translation_worker();
END;
$$;

-- Jobs list with a human readable title
CREATE OR REPLACE FUNCTION public.tp_jobs(
  p_status text DEFAULT NULL,
  p_content_type text DEFAULT NULL,
  p_search text DEFAULT NULL,
  p_limit integer DEFAULT 100,
  p_offset integer DEFAULT 0
)
RETURNS TABLE (
  id bigint, content_type text, record_id text, title text, status text, attempts integer,
  revision bigint, last_error text, next_retry_at timestamptz, locked_by text,
  updated_at timestamptz, completed_at timestamptz, total_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.tp_require_admin();
  RETURN QUERY
  WITH titled AS (
    SELECT j.*,
      coalesce(
        CASE j.content_type
          WHEN 'post' THEN (SELECT p.title FROM public.posts p WHERE p.id::text = j.record_id)
          WHEN 'message' THEN (SELECT m.title FROM public.messages m WHERE m.id::text = j.record_id)
          WHEN 'impulse' THEN (SELECT i.title FROM public.impulses i WHERE i.id::text = j.record_id)
          WHEN 'video' THEN (SELECT v.title FROM public.videos v WHERE v.id::text = j.record_id)
          WHEN 'verse' THEN (SELECT vd.reference || ' (' || vd.date::text || ')' FROM public.verse_of_the_day vd WHERE vd.id::text = j.record_id)
          WHEN 'poll' THEN (SELECT pl.question FROM public.polls pl WHERE pl.id::text = j.record_id)
          WHEN 'edition' THEN (SELECT coalesce(e.title, e.name) FROM public.editions e WHERE e.id::text = j.record_id)
          WHEN 'category' THEN (SELECT c.name FROM public.categories c WHERE c.id::text = j.record_id)
        END, j.record_id) AS t
    FROM public.translation_jobs j
    WHERE (p_status IS NULL OR j.status = p_status)
      AND (p_content_type IS NULL OR j.content_type = p_content_type)
  ), filtered AS (
    SELECT * FROM titled
    WHERE p_search IS NULL OR p_search = '' OR titled.t ILIKE '%' || p_search || '%'
       OR titled.record_id = p_search OR titled.last_error ILIKE '%' || p_search || '%'
  )
  SELECT f.id, f.content_type, f.record_id, f.t, f.status, f.attempts, f.revision, f.last_error,
         f.next_retry_at, f.locked_by, f.updated_at, f.completed_at, count(*) OVER ()
  FROM filtered f
  ORDER BY (f.status = 'processing') DESC, f.updated_at DESC
  LIMIT LEAST(greatest(p_limit, 1), 500) OFFSET greatest(p_offset, 0);
END;
$$;

-- Translations of one record (for the detail drawer)
CREATE OR REPLACE FUNCTION public.tp_record_translations(p_content_type text, p_record_id text)
RETURNS TABLE (language text, field_name text, value text, status text, updated_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_cid uuid;
BEGIN
  PERFORM public.tp_require_admin();
  IF p_content_type IN ('edition', 'category') THEN
    RETURN QUERY SELECT e.language, e.field_name, e.value, e.status, e.updated_at
      FROM public.entity_translations e
      WHERE e.entity_type = p_content_type AND e.entity_id = p_record_id
      ORDER BY e.language, e.field_name;
  ELSE
    SELECT s.content_id INTO v_cid FROM public.tp_content_ids(p_content_type) s WHERE s.record_id = p_record_id;
    RETURN QUERY SELECT c.language, c.field_name, c.value, c.status, c.updated_at
      FROM public.content_translations c WHERE c.content_id = v_cid
      ORDER BY c.language, c.field_name;
  END IF;
END;
$$;

-- Recent worker invocations (pg_net keeps responses ~6h)
CREATE OR REPLACE FUNCTION public.tp_worker_runs(p_limit integer DEFAULT 50)
RETURNS TABLE (id bigint, status_code integer, created timestamptz, error_msg text, body text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, net
AS $$
BEGIN
  PERFORM public.tp_require_admin();
  RETURN QUERY
  SELECT r.id, r.status_code, r.created, r.error_msg, left(r.content, 20000)
  FROM net._http_response r
  WHERE r.content ILIKE '%"processed"%' OR r.content ILIKE '%[translation]%'
     OR (r.status_code >= 500 AND r.content ILIKE '%"ok": false%')
  ORDER BY r.created DESC
  LIMIT LEAST(greatest(p_limit, 1), 200);
EXCEPTION WHEN OTHERS THEN
  RETURN;
END;
$$;

-- Audios with their post title + existing translations
CREATE OR REPLACE FUNCTION public.tp_audios()
RETURNS TABLE (audio_id uuid, url text, created_at timestamptz, post_id uuid, title text,
               image_url text, edition text, translations jsonb)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.tp_require_admin();
  RETURN QUERY
  SELECT a.id, a.url, a.created_at, p.id, coalesce(p.title, '(ohne Artikel)'), p.image_url,
         (SELECT coalesce(e.title, e.name) FROM public.editions e WHERE e.id = p.edition_id),
         coalesce((SELECT jsonb_agg(jsonb_build_object('id', t.id, 'language', t.language, 'url', t.url,
                                                       'file_name', t.file_name, 'storage_path', t.storage_path,
                                                       'updated_at', t.updated_at) ORDER BY t.language)
                   FROM public.audio_translations t WHERE t.audio_id = a.id), '[]'::jsonb)
  FROM public.audios a
  LEFT JOIN LATERAL (SELECT * FROM public.posts px WHERE px.audio_id = a.id ORDER BY px.created_at DESC LIMIT 1) p ON true
  ORDER BY a.created_at DESC NULLS LAST;
END;
$$;

REVOKE ALL ON FUNCTION public.tp_overview() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_retry_failed(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_run_now() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_rerun_type(text, boolean) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_rerun_record(text, text, boolean) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_jobs(text, text, text, integer, integer) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_record_translations(text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_worker_runs(integer) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_audios() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.tp_overview(), public.tp_retry_failed(text), public.tp_run_now(),
  public.tp_rerun_type(text, boolean), public.tp_rerun_record(text, text, boolean),
  public.tp_jobs(text, text, text, integer, integer), public.tp_record_translations(text, text),
  public.tp_worker_runs(integer), public.tp_audios(), public.tp_is_admin() TO authenticated;

COMMIT;
