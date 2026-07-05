-- ============================================================================
-- Migration: Universal "Likes" system for ALL content types
-- (posts / Beiträge, audios, messages / Kurznachrichten, editions / Ausgaben,
--  videos, impulses, polls, ... anything identified by content_id+content_type)
--
-- Mirrors the existing anonymous, device_id-based tracking pattern already
-- used by `content_interactions` / `post_view_counts` / `device_tokens`.
--
-- This migration is idempotent: it can be re-run safely without erroring.
--
-- Backend contract expected by the Flutter app (already implemented in
-- lib/core/services/like_service.dart):
--   • table `likes` (content_id, content_type, device_id, ...)
--   • RPC `toggle_like(p_content_id, p_content_type, p_device_id)`
--       -> returns rows with columns (liked boolean, like_count bigint)
-- ============================================================================

-- 1. Table: one row per (content, device) like
CREATE TABLE IF NOT EXISTS likes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id text NOT NULL,
  content_type text NOT NULL,      -- 'post', 'audio', 'edition', 'video', 'impulse', 'message', 'poll', ...
  device_id text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT likes_unique_device_content UNIQUE (content_id, content_type, device_id)
);

-- 2. Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_likes_content ON likes(content_id, content_type);
CREATE INDEX IF NOT EXISTS idx_likes_device ON likes(device_id);

-- 3. Row Level Security
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- Everyone (anonymous or not) can read likes, so like counts are public.
DROP POLICY IF EXISTS "Anyone can read likes" ON likes;
CREATE POLICY "Anyone can read likes"
  ON likes
  FOR SELECT
  TO public
  USING (true);

-- Anyone can like content (anonymous device-based tracking, same trust model
-- as content_interactions / device_tokens elsewhere in this app).
DROP POLICY IF EXISTS "Anyone can insert likes" ON likes;
CREATE POLICY "Anyone can insert likes"
  ON likes
  FOR INSERT
  TO public
  WITH CHECK (true);

-- Anyone can remove a like (unlike). The toggle_like() RPC is the normal
-- entry point and always scopes deletes to the caller's own device_id.
DROP POLICY IF EXISTS "Anyone can delete likes" ON likes;
CREATE POLICY "Anyone can delete likes"
  ON likes
  FOR DELETE
  TO public
  USING (true);

-- 4. Realtime (optional, future-proofing): lets the app subscribe to live
--    like changes later, exactly like `post_view_counts` already does.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'likes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE likes;
  END IF;
END $$;

-- 5. RPC: toggle_like — atomically like/unlike and return the fresh state.
--    SECURITY DEFINER so it works reliably regardless of RLS/role nuances,
--    same approach as increment_post_view_count().
CREATE OR REPLACE FUNCTION toggle_like(
  p_content_id text,
  p_content_type text,
  p_device_id text
)
RETURNS TABLE(liked boolean, like_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existed boolean;
  v_count bigint;
BEGIN
  IF p_content_id IS NULL OR p_content_type IS NULL OR p_device_id IS NULL THEN
    RAISE EXCEPTION 'content_id, content_type and device_id are required';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM likes
    WHERE content_id = p_content_id
      AND content_type = p_content_type
      AND device_id = p_device_id
  ) INTO v_existed;

  IF v_existed THEN
    DELETE FROM likes
    WHERE content_id = p_content_id
      AND content_type = p_content_type
      AND device_id = p_device_id;
  ELSE
    INSERT INTO likes (content_id, content_type, device_id)
    VALUES (p_content_id, p_content_type, p_device_id)
    ON CONFLICT (content_id, content_type, device_id) DO NOTHING;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM likes
  WHERE content_id = p_content_id
    AND content_type = p_content_type;

  RETURN QUERY SELECT (NOT v_existed) AS liked, v_count AS like_count;
END;
$$;

-- 6. Helper RPC: fetch like counts for many content items at once
--    (handy for list screens later; not required by the current app, but
--    cheap insurance so future list views don't need N calls).
CREATE OR REPLACE FUNCTION get_like_counts(p_content_type text, p_content_ids text[])
RETURNS TABLE(content_id text, like_count bigint)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT l.content_id, COUNT(*) AS like_count
  FROM likes l
  WHERE l.content_type = p_content_type
    AND l.content_id = ANY(p_content_ids)
  GROUP BY l.content_id;
$$;

-- 7. Grants — Supabase's `anon`/`authenticated` roles must be able to call
--    these RPCs and read/write the table (RLS above still governs rows).
GRANT SELECT, INSERT, DELETE ON likes TO anon, authenticated;
GRANT EXECUTE ON FUNCTION toggle_like(text, text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_like_counts(text, text[]) TO anon, authenticated;
