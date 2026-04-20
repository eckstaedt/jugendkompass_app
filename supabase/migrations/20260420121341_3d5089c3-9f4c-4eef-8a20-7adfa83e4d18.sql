
-- =========================================================
-- 1) content_translations
-- =========================================================
CREATE TABLE IF NOT EXISTS public.content_translations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id uuid NOT NULL REFERENCES public.content(id) ON DELETE CASCADE,
  language text NOT NULL,
  field_name text NOT NULL,
  value text NOT NULL,
  source_hash text,
  status text NOT NULL DEFAULT 'auto',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (content_id, language, field_name)
);

CREATE INDEX IF NOT EXISTS idx_content_translations_content
  ON public.content_translations (content_id, language);
CREATE INDEX IF NOT EXISTS idx_content_translations_lang
  ON public.content_translations (language);

ALTER TABLE public.content_translations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read translations" ON public.content_translations;
CREATE POLICY "Anyone can read translations"
  ON public.content_translations FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can insert translations" ON public.content_translations;
CREATE POLICY "Admins can insert translations"
  ON public.content_translations FOR INSERT
  WITH CHECK (public.is_admin(auth.uid()));

DROP POLICY IF EXISTS "Admins can update translations" ON public.content_translations;
CREATE POLICY "Admins can update translations"
  ON public.content_translations FOR UPDATE
  USING (public.is_admin(auth.uid()));

DROP POLICY IF EXISTS "Admins can delete translations" ON public.content_translations;
CREATE POLICY "Admins can delete translations"
  ON public.content_translations FOR DELETE
  USING (public.is_admin(auth.uid()));

CREATE OR REPLACE FUNCTION public.touch_content_translations_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_touch_content_translations ON public.content_translations;
CREATE TRIGGER trg_touch_content_translations
  BEFORE UPDATE ON public.content_translations
  FOR EACH ROW EXECUTE FUNCTION public.touch_content_translations_updated_at();

-- =========================================================
-- 2) device_tokens.language
-- =========================================================
ALTER TABLE public.device_tokens
  ADD COLUMN IF NOT EXISTS language text NOT NULL DEFAULT 'de';

-- =========================================================
-- 3) Helper
-- =========================================================
CREATE OR REPLACE FUNCTION public.tr(
  p_content_id uuid,
  p_lang text,
  p_field text,
  p_fallback text
) RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(
    (SELECT value FROM public.content_translations
      WHERE content_id = p_content_id AND language = p_lang AND field_name = p_field
      LIMIT 1),
    p_fallback
  );
$$;

-- =========================================================
-- 4) Localized RPCs
-- =========================================================
CREATE OR REPLACE FUNCTION public.get_posts_localized(lang text)
RETURNS TABLE (
  id uuid, title text, body text, category_id uuid, edition_id uuid,
  content_id uuid, audio_id uuid, image_url text, created_at timestamptz
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p.id,
    public.tr(p.content_id, lang, 'title', p.title),
    public.tr(p.content_id, lang, 'body',  p.body),
    p.category_id, p.edition_id, p.content_id, p.audio_id, p.image_url, p.created_at
  FROM public.posts p;
$$;

CREATE OR REPLACE FUNCTION public.get_impulses_localized(lang text)
RETURNS TABLE (
  id uuid, content_id uuid, title text, date date,
  impulse_text text, image_url text, created_at timestamptz
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT i.id, i.content_id,
    public.tr(i.content_id, lang, 'title', i.title),
    i.date,
    public.tr(i.content_id, lang, 'impulse_text', i.impulse_text),
    i.image_url, i.created_at
  FROM public.impulses i;
$$;

CREATE OR REPLACE FUNCTION public.get_verse_of_day_localized(lang text)
RETURNS TABLE (
  id uuid, content_id uuid, verse text, reference text, date date, created_at timestamptz
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT v.id, v.content_id,
    public.tr(v.content_id, lang, 'verse', v.verse),
    public.tr(v.content_id, lang, 'reference', v.reference),
    v.date, v.created_at
  FROM public.verse_of_the_day v;
$$;

CREATE OR REPLACE FUNCTION public.get_messages_localized(lang text)
RETURNS TABLE (
  id integer, content_id uuid, title text, message text,
  image_url text, created_by uuid, created_at timestamptz
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT m.id, m.content_id,
    public.tr(m.content_id, lang, 'title', m.title),
    public.tr(m.content_id, lang, 'message', m.message),
    m.image_url, m.created_by, m.created_at
  FROM public.messages m;
$$;

CREATE OR REPLACE FUNCTION public.get_polls_localized(lang text)
RETURNS TABLE (
  id uuid, content_id uuid, question text, is_active boolean,
  expires_at timestamptz, created_by uuid, created_at timestamptz
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p.id, p.content_id,
    public.tr(p.content_id, lang, 'question', p.question),
    p.is_active, p.expires_at, p.created_by, p.created_at
  FROM public.polls p;
$$;

CREATE OR REPLACE FUNCTION public.get_poll_options_localized(lang text)
RETURNS TABLE (
  id uuid, poll_id uuid, option_text text, votes integer, created_at timestamptz
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT o.id, o.poll_id,
    COALESCE(
      (SELECT t.value FROM public.content_translations t
         JOIN public.polls pp ON pp.id = o.poll_id
        WHERE t.content_id = pp.content_id
          AND t.language = lang
          AND t.field_name = 'option:' || o.id::text
        LIMIT 1),
      o.option_text
    ),
    o.votes, o.created_at
  FROM public.poll_options o;
$$;

CREATE OR REPLACE FUNCTION public.get_videos_localized(lang text)
RETURNS TABLE (
  id integer, content_id uuid, title text, description text,
  url text, image_url text, user_id uuid, created_at timestamptz
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT v.id, v.content_id,
    public.tr(v.content_id, lang, 'title', v.title),
    public.tr(v.content_id, lang, 'description', v.description),
    v.url, v.image_url, v.user_id, v.created_at
  FROM public.videos v;
$$;

CREATE OR REPLACE FUNCTION public.get_editions_localized(lang text)
RETURNS TABLE (
  id uuid, name text, title text, body text,
  image_url text, pdf_url text, published_at timestamptz
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT e.id, e.name, e.title, e.body, e.image_url, e.pdf_url, e.published_at
  FROM public.editions e;
$$;

CREATE OR REPLACE FUNCTION public.get_categories_localized(lang text)
RETURNS TABLE (id uuid, name text, created_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT c.id, c.name, c.created_at FROM public.categories c;
$$;

-- entity_id and specific_date are TEXT in the existing content_feed view
CREATE OR REPLACE FUNCTION public.get_content_feed_localized(lang text)
RETURNS TABLE (
  content_id uuid, content_type text, created_at timestamptz,
  title text, description text, image_url text,
  entity_id text, sort_order integer, specific_date text
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT
    f.content_id, f.content_type, f.created_at,
    public.tr(f.content_id, lang, 'title',       f.title),
    public.tr(f.content_id, lang, 'description', f.description),
    f.image_url, f.entity_id, f.sort_order, f.specific_date
  FROM public.content_feed f;
$$;
