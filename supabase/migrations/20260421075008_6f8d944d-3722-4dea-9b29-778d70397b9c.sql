CREATE OR REPLACE FUNCTION public.notify_translate_content()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_content_id uuid;
  v_url text := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/translate-content';
  v_key text := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkY2RpYnZjbGF1bHF4Zmp5enBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTQ1OTE4OSwiZXhwIjoyMDgxMDM1MTg5fQ.I29tT_hib4cHHfwY-Iep_lA9iSBjP0UL7xKNUb1TDyQ';
BEGIN
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
      'target_languages', jsonb_build_array('en', 'es', 'ru', 'pl'),
      'force', false
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    )
  );

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_translate_poll_option()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
      'target_languages', jsonb_build_array('en', 'es', 'ru', 'pl'),
      'force', false
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    )
  );
  RETURN NEW;
END;
$function$;