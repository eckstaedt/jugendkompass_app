-- Ensure verse localization always uses the `reference` field for localized references.
-- This redefines the verse RPCs so EN (and other non-DE languages) consistently
-- read translated references from field_name = 'reference'.

BEGIN;

DROP FUNCTION IF EXISTS public.get_verse_of_day_localized(text);
CREATE OR REPLACE FUNCTION public.get_verse_of_day_localized(lang text)
RETURNS TABLE (
  id uuid,
  content_id uuid,
  verse text,
  reference text,
  date date
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF lang = 'de' THEN
    RETURN QUERY
    SELECT
      v.id,
      v.content_id,
      v.verse,
      v.reference,
      v.date
    FROM public.verse_of_the_day v
    WHERE v.date = CURRENT_DATE
    ORDER BY v.created_at DESC
    LIMIT 1;
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    v.id,
    v.content_id,
    COALESCE(public.tr(v.content_id, lang, 'verse', NULL), v.verse) AS verse,
    COALESCE(public.tr(v.content_id, lang, 'reference', NULL), v.reference) AS reference,
    v.date
  FROM public.verse_of_the_day v
  WHERE v.date = CURRENT_DATE
  ORDER BY v.created_at DESC
  LIMIT 1;
END;
$$;

DROP FUNCTION IF EXISTS public.get_recent_verses_localized(text, integer);
CREATE OR REPLACE FUNCTION public.get_recent_verses_localized(
  lang text,
  verse_limit integer DEFAULT 10
)
RETURNS TABLE (
  id uuid,
  content_id uuid,
  verse text,
  reference text,
  date date
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF lang = 'de' THEN
    RETURN QUERY
    SELECT
      v.id,
      v.content_id,
      v.verse,
      v.reference,
      v.date
    FROM public.verse_of_the_day v
    ORDER BY v.date DESC, v.created_at DESC
    LIMIT verse_limit;
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    v.id,
    v.content_id,
    COALESCE(public.tr(v.content_id, lang, 'verse', NULL), v.verse) AS verse,
    COALESCE(public.tr(v.content_id, lang, 'reference', NULL), v.reference) AS reference,
    v.date
  FROM public.verse_of_the_day v
  ORDER BY v.date DESC, v.created_at DESC
  LIMIT verse_limit;
END;
$$;

DROP FUNCTION IF EXISTS public.get_verse_archive_localized(text, integer, integer);
CREATE OR REPLACE FUNCTION public.get_verse_archive_localized(
  lang text,
  page_limit integer DEFAULT 20,
  page_offset integer DEFAULT 0
)
RETURNS TABLE (
  id uuid,
  content_id uuid,
  verse text,
  reference text,
  date date,
  image_url text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF lang = 'de' THEN
    RETURN QUERY
    SELECT
      v.id,
      v.content_id,
      v.verse,
      v.reference,
      v.date,
      v.image_url
    FROM public.verse_of_the_day v
    WHERE v.date <= CURRENT_DATE
    ORDER BY v.date DESC, v.created_at DESC
    LIMIT page_limit OFFSET page_offset;
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    v.id,
    v.content_id,
    COALESCE(public.tr(v.content_id, lang, 'verse', NULL), v.verse) AS verse,
    COALESCE(public.tr(v.content_id, lang, 'reference', NULL), v.reference) AS reference,
    v.date,
    v.image_url
  FROM public.verse_of_the_day v
  WHERE v.date <= CURRENT_DATE
  ORDER BY v.date DESC, v.created_at DESC
  LIMIT page_limit OFFSET page_offset;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_verse_of_day_localized(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_recent_verses_localized(text, integer) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_verse_archive_localized(text, integer, integer) TO anon, authenticated;

COMMENT ON FUNCTION public.get_verse_of_day_localized IS
  'Returns today''s verse localized by language, using field_name=reference for localized references.';

COMMENT ON FUNCTION public.get_recent_verses_localized IS
  'Returns recent verses localized by language, using field_name=reference for localized references.';

COMMENT ON FUNCTION public.get_verse_archive_localized IS
  'Returns verse archive localized by language (past verses only), using field_name=reference for localized references.';

COMMIT;
