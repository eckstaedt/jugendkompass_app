-- Generische Trigger-Funktion: ruft translate-content asynchron via pg_net auf
CREATE OR REPLACE FUNCTION public.notify_translate_content()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_content_id uuid;
  v_url text := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/translate-content';
  v_key text := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkY2RpYnZjbGF1bHF4Zmp5enBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTQ1OTE4OSwiZXhwIjoyMDgxMDM1MTg5fQ.I29tT_hib4cHHfwY-Iep_lA9iSBjP0UL7xKNUb1TDyQ';
BEGIN
  -- content_id ermitteln (alle Zieltabellen haben diese Spalte)
  BEGIN
    v_content_id := (to_jsonb(NEW) ->> 'content_id')::uuid;
  EXCEPTION WHEN OTHERS THEN
    v_content_id := NULL;
  END;

  IF v_content_id IS NULL THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url     := v_url,
    body    := jsonb_build_object(
      'content_id', v_content_id,
      'target_languages', jsonb_build_array('en'),
      'force', false
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    )
  );

  RETURN NEW;
END;
$$;

-- POSTS: title, body
DROP TRIGGER IF EXISTS trg_translate_posts ON public.posts;
CREATE TRIGGER trg_translate_posts
AFTER INSERT OR UPDATE OF title, body ON public.posts
FOR EACH ROW
WHEN (NEW.content_id IS NOT NULL)
EXECUTE FUNCTION public.notify_translate_content();

-- IMPULSES: title, impulse_text
DROP TRIGGER IF EXISTS trg_translate_impulses ON public.impulses;
CREATE TRIGGER trg_translate_impulses
AFTER INSERT OR UPDATE OF title, impulse_text ON public.impulses
FOR EACH ROW
WHEN (NEW.content_id IS NOT NULL)
EXECUTE FUNCTION public.notify_translate_content();

-- MESSAGES: title, message
DROP TRIGGER IF EXISTS trg_translate_messages ON public.messages;
CREATE TRIGGER trg_translate_messages
AFTER INSERT OR UPDATE OF title, message ON public.messages
FOR EACH ROW
WHEN (NEW.content_id IS NOT NULL)
EXECUTE FUNCTION public.notify_translate_content();

-- VERSE_OF_THE_DAY: verse, reference
DROP TRIGGER IF EXISTS trg_translate_verses ON public.verse_of_the_day;
CREATE TRIGGER trg_translate_verses
AFTER INSERT OR UPDATE OF verse, reference ON public.verse_of_the_day
FOR EACH ROW
WHEN (NEW.content_id IS NOT NULL)
EXECUTE FUNCTION public.notify_translate_content();

-- VIDEOS: title, description
DROP TRIGGER IF EXISTS trg_translate_videos ON public.videos;
CREATE TRIGGER trg_translate_videos
AFTER INSERT OR UPDATE OF title, description ON public.videos
FOR EACH ROW
WHEN (NEW.content_id IS NOT NULL)
EXECUTE FUNCTION public.notify_translate_content();

-- POLLS: question
DROP TRIGGER IF EXISTS trg_translate_polls ON public.polls;
CREATE TRIGGER trg_translate_polls
AFTER INSERT OR UPDATE OF question ON public.polls
FOR EACH ROW
WHEN (NEW.content_id IS NOT NULL)
EXECUTE FUNCTION public.notify_translate_content();

-- POLL_OPTIONS: option_text (verknüpft via polls.content_id)
CREATE OR REPLACE FUNCTION public.notify_translate_poll_option()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_content_id uuid;
  v_url text := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/translate-content';
  v_key text := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkY2RpYnZjbGF1bHF4Zmp5enBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTQ1OTE4OSwiZXhwIjoyMDgxMDM1MTg5fQ.I29tT_hib4cHHfwY-Iep_lA9iSBjP0UL7xKNUb1TDyQ';
BEGIN
  SELECT content_id INTO v_content_id FROM public.polls WHERE id = NEW.poll_id;
  IF v_content_id IS NULL THEN RETURN NEW; END IF;

  PERFORM net.http_post(
    url := v_url,
    body := jsonb_build_object(
      'content_id', v_content_id,
      'target_languages', jsonb_build_array('en'),
      'force', false
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    )
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_translate_poll_options ON public.poll_options;
CREATE TRIGGER trg_translate_poll_options
AFTER INSERT OR UPDATE OF option_text ON public.poll_options
FOR EACH ROW
EXECUTE FUNCTION public.notify_translate_poll_option();