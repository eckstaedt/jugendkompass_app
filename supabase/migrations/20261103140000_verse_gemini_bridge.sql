-- ═══════════════════════════════════════════════════════════════════════════
-- ÜBERGANG: Vers des Tages mit Gemini (Lovable-Funktion translate-content)
-- übersetzen, solange der Claude-Übersetzer (process-translation-jobs) keine
-- Credits hat.
--
--  • Verse der nächsten 30 Tage ohne vollständige Übersetzung werden alle
--    10 Minuten (je 4 Stück) an translate-content geschickt (alle 6 Sprachen).
--  • Neu angelegte / geänderte Verse (Admin) werden sofort übersetzt.
--  • Der Claude-Übersetzer überschreibt diese Übersetzungen später automatisch.
--
-- Für die Anmeldung wird derselbe Schlüssel verwendet, den die bestehende
-- Funktion notify_translate_content() bereits nutzt (er wird aus deren
-- Definition gelesen, damit er nicht noch einmal im Repo steht).
--
-- Abschalten (wenn Claude läuft):  select public.disable_verse_gemini_bridge();
-- ═══════════════════════════════════════════════════════════════════════════

BEGIN;

CREATE TABLE IF NOT EXISTS public.verse_gemini_attempts (
  content_id uuid PRIMARY KEY,
  last_try timestamptz NOT NULL DEFAULT now(),
  tries integer NOT NULL DEFAULT 1
);
ALTER TABLE public.verse_gemini_attempts ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.gemini_translate_verse(p_content_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_key text;
  v_url text;
BEGIN
  IF p_content_id IS NULL THEN
    RETURN false;
  END IF;

  SELECT substring(pg_get_functiondef(p.oid) FROM 'v_key text := ''([^'']+)'''),
         substring(pg_get_functiondef(p.oid) FROM 'v_url text := ''([^'']+)''')
    INTO v_key, v_url
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname = 'notify_translate_content'
  LIMIT 1;

  IF v_key IS NULL THEN
    RAISE WARNING 'gemini_translate_verse: notify_translate_content() not found – cannot call translate-content';
    RETURN false;
  END IF;
  v_url := coalesce(v_url, 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/translate-content');

  PERFORM net.http_post(
    url := v_url,
    body := jsonb_build_object(
      'content_id', p_content_id,
      'target_languages', jsonb_build_array('en', 'ru', 'es', 'pl', 'tr', 'he'),
      'force', true
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    timeout_milliseconds := 120000
  );

  INSERT INTO public.verse_gemini_attempts (content_id) VALUES (p_content_id)
  ON CONFLICT (content_id) DO UPDATE
    SET last_try = now(), tries = public.verse_gemini_attempts.tries + 1;
  RETURN true;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'gemini_translate_verse failed: %', SQLERRM;
  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.gemini_translate_verse(uuid) FROM PUBLIC, anon, authenticated;

-- Verse der nächsten p_days Tage, denen eine der 12 Übersetzungen
-- (6 Sprachen × verse/reference) fehlt; höchstens p_limit pro Lauf, jeder
-- Vers höchstens alle 6 Stunden erneut.
CREATE OR REPLACE FUNCTION public.run_verse_gemini_bridge(p_days integer DEFAULT 30, p_limit integer DEFAULT 4)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r record;
  n integer := 0;
BEGIN
  FOR r IN
    SELECT v.content_id
    FROM public.verse_of_the_day v
    LEFT JOIN public.verse_gemini_attempts a ON a.content_id = v.content_id
    WHERE v.date BETWEEN current_date AND current_date + p_days
      AND (a.last_try IS NULL OR a.last_try < now() - interval '6 hours')
      AND (
        SELECT count(*) FROM public.content_translations ct
        WHERE ct.content_id = v.content_id
          AND ct.field_name IN ('verse', 'reference')
          AND ct.language IN ('en', 'ru', 'es', 'pl', 'tr', 'he')
          AND coalesce(ct.value, '') <> ''
      ) < 12
    ORDER BY v.date
    LIMIT p_limit
  LOOP
    IF public.gemini_translate_verse(r.content_id) THEN
      n := n + 1;
    END IF;
  END LOOP;
  RETURN n;
END;
$$;

REVOKE ALL ON FUNCTION public.run_verse_gemini_bridge(integer, integer) FROM PUBLIC, anon, authenticated;

-- Sofort übersetzen, wenn im Admin ein Vers angelegt oder Text/Referenz geändert wird
CREATE OR REPLACE FUNCTION public.trg_verse_gemini_bridge()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.date <= current_date + 60 THEN
    PERFORM public.gemini_translate_verse(NEW.content_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_verse_gemini_bridge ON public.verse_of_the_day;
CREATE TRIGGER trg_verse_gemini_bridge
AFTER INSERT OR UPDATE OF verse, reference ON public.verse_of_the_day
FOR EACH ROW EXECUTE FUNCTION public.trg_verse_gemini_bridge();

CREATE OR REPLACE FUNCTION public.disable_verse_gemini_bridge()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DROP TRIGGER IF EXISTS trg_verse_gemini_bridge ON public.verse_of_the_day;
  IF to_regclass('cron.job') IS NOT NULL THEN
    PERFORM cron.unschedule(jobid) FROM cron.job WHERE jobname = 'verse-gemini-bridge';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.disable_verse_gemini_bridge() FROM PUBLIC, anon, authenticated;

DO $$
BEGIN
  IF to_regclass('cron.job') IS NOT NULL THEN
    PERFORM cron.unschedule(jobid) FROM cron.job WHERE jobname = 'verse-gemini-bridge';
    PERFORM cron.schedule('verse-gemini-bridge', '*/10 * * * *', 'select public.run_verse_gemini_bridge(30, 4);');
  END IF;
END
$$;

COMMIT;

-- direkt die ersten Verse anstoßen (heute + nächste Tage)
SELECT public.run_verse_gemini_bridge(30, 4) AS gestartet;
