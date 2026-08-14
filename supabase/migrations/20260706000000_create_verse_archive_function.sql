-- Migration: "Vers des Tages Archiv" (Verse of the Day Archive)
-- Adds a paginated, localized RPC that returns all PAST verse_of_the_day
-- rows (newest first, up to and including today), including image_url, so
-- the Flutter app can show a full history of every verse that has ever
-- been the verse of the day. Future-dated (pre-scheduled) verses are
-- excluded so the archive never spoils upcoming daily verses.
--
-- No RLS changes are needed: verse_of_the_day is already readable by
-- everyone (anon + authenticated), which is what powers the direct table
-- query used for the German locale. This migration only adds the RPC used
-- for non-German locales (mirrors the existing get_recent_verses_localized
-- pattern from improve_verse_localization.sql, but adds image_url + offset
-- support for pagination/infinite-scroll).

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
  -- For German, return original (untranslated) data.
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

  -- For other languages, return translated verse/reference, falling back
  -- to the German original when no translation exists.
  RETURN QUERY
  SELECT
    v.id,
    v.content_id,
    COALESCE(
      public.tr(v.content_id, lang, 'verse', NULL),
      v.verse
    ) AS verse,
    COALESCE(
      public.tr(v.content_id, lang, 'reference', NULL),
      v.reference
    ) AS reference,
    v.date,
    v.image_url
  FROM public.verse_of_the_day v
  WHERE v.date <= CURRENT_DATE
  ORDER BY v.date DESC, v.created_at DESC
  LIMIT page_limit OFFSET page_offset;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_verse_archive_localized(text, integer, integer) TO anon, authenticated;

COMMENT ON FUNCTION public.get_verse_archive_localized IS
  'Returns a paginated (newest first) list of every PAST verse_of_the_day entry (date <= today), localized for the given language, including image_url for share-ability checks. Used by the Vers des Tages Archiv screen.';
