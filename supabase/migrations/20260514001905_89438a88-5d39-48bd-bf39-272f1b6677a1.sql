
ALTER TABLE public.editions ADD COLUMN IF NOT EXISTS content_id uuid;

DO $$
DECLARE r record; new_id uuid;
BEGIN
  FOR r IN SELECT id FROM public.editions WHERE content_id IS NULL LOOP
    INSERT INTO public.content (content_type, status) VALUES ('edition', 'published') RETURNING id INTO new_id;
    UPDATE public.editions SET content_id = new_id WHERE id = r.id;
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.handle_edition_content()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.content_id IS NULL THEN
    INSERT INTO public.content (content_type, status)
    VALUES ('edition', 'published')
    RETURNING id INTO NEW.content_id;
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_handle_edition_content ON public.editions;
CREATE TRIGGER trg_handle_edition_content
BEFORE INSERT ON public.editions
FOR EACH ROW EXECUTE FUNCTION public.handle_edition_content();

DROP TRIGGER IF EXISTS trg_notify_translate_edition ON public.editions;
CREATE TRIGGER trg_notify_translate_edition
AFTER INSERT OR UPDATE OF title, body ON public.editions
FOR EACH ROW EXECUTE FUNCTION public.notify_translate_content();

DROP FUNCTION IF EXISTS public.get_editions_localized(text);
CREATE FUNCTION public.get_editions_localized(lang text)
RETURNS TABLE(id uuid, content_id uuid, name text, title text, body text, image_url text, pdf_url text, published_at timestamp with time zone)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public' AS $$
  SELECT e.id, e.content_id, e.name,
    public.tr(e.content_id, lang, 'title', e.title),
    public.tr(e.content_id, lang, 'body',  e.body),
    e.image_url, e.pdf_url, e.published_at
  FROM public.editions e;
$$;
