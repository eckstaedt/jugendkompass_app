-- Drop existing functions first
DROP FUNCTION IF EXISTS public.get_verse_of_day_localized(text);
DROP FUNCTION IF EXISTS public.get_verse_by_id_localized(uuid, text);
DROP FUNCTION IF EXISTS public.get_recent_verses_localized(text, integer);

-- Improved RPC function for getting localized verse of the day
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
  -- For German, return original data
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

  -- For other languages, return translated data
  RETURN QUERY
  SELECT
    v.id,
    v.content_id,
    COALESCE(
      public.tr(v.content_id, lang, 'verse', NULL),
      v.verse
    ) as verse,
    COALESCE(
      public.tr(v.content_id, lang, 'reference', NULL),
      v.reference
    ) as reference,
    v.date
  FROM public.verse_of_the_day v
  WHERE v.date = CURRENT_DATE
  ORDER BY v.created_at DESC
  LIMIT 1;
END;
$$;

-- Create a function to get verse by ID with localization
CREATE OR REPLACE FUNCTION public.get_verse_by_id_localized(verse_id uuid, lang text)
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
  -- For German, return original data
  IF lang = 'de' THEN
    RETURN QUERY
    SELECT
      v.id,
      v.content_id,
      v.verse,
      v.reference,
      v.date
    FROM public.verse_of_the_day v
    WHERE v.id = verse_id;
    RETURN;
  END IF;

  -- For other languages, return translated data
  RETURN QUERY
  SELECT
    v.id,
    v.content_id,
    COALESCE(
      public.tr(v.content_id, lang, 'verse', NULL),
      v.verse
    ) as verse,
    COALESCE(
      public.tr(v.content_id, lang, 'reference', NULL),
      v.reference
    ) as reference,
    v.date
  FROM public.verse_of_the_day v
  WHERE v.id = verse_id;
END;
$$;

-- Create a function to get recent verses with localization
CREATE OR REPLACE FUNCTION public.get_recent_verses_localized(lang text, verse_limit integer DEFAULT 10)
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
  -- For German, return original data
  IF lang = 'de' THEN
    RETURN QUERY
    SELECT
      v.id,
      v.content_id,
      v.verse,
      v.reference,
      v.date
    FROM public.verse_of_the_day v
    ORDER BY v.date DESC
    LIMIT verse_limit;
    RETURN;
  END IF;

  -- For other languages, return translated data
  RETURN QUERY
  SELECT
    v.id,
    v.content_id,
    COALESCE(
      public.tr(v.content_id, lang, 'verse', NULL),
      v.verse
    ) as verse,
    COALESCE(
      public.tr(v.content_id, lang, 'reference', NULL),
      v.reference
    ) as reference,
    v.date
  FROM public.verse_of_the_day v
  ORDER BY v.date DESC
  LIMIT verse_limit;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_verse_of_day_localized(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_verse_by_id_localized(uuid, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_recent_verses_localized(text, integer) TO anon, authenticated;

COMMENT ON FUNCTION public.get_verse_of_day_localized IS 'Returns today''s verse of the day with translations for the specified language';
COMMENT ON FUNCTION public.get_verse_by_id_localized IS 'Returns a specific verse by ID with translations for the specified language';
COMMENT ON FUNCTION public.get_recent_verses_localized IS 'Returns recent verses with translations for the specified language';
