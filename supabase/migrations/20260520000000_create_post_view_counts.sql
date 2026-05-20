-- Migration: Create post_view_counts table for realtime view counting
-- This table is publicly readable so all users can see live view counts.
-- It is automatically updated via a trigger on content_interactions INSERT.

-- 1. Create the table
CREATE TABLE IF NOT EXISTS post_view_counts (
  content_id text PRIMARY KEY,
  view_count bigint NOT NULL DEFAULT 0,
  last_updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2. Enable RLS
ALTER TABLE post_view_counts ENABLE ROW LEVEL SECURITY;

-- 3. Public read access (everyone can see view counts)
CREATE POLICY "Anyone can read post view counts"
  ON post_view_counts
  FOR SELECT
  TO public
  USING (true);

-- 4. Enable Realtime so Flutter can subscribe to changes
ALTER PUBLICATION supabase_realtime ADD TABLE post_view_counts;

-- 5. Trigger function: increment view count on each content_interactions INSERT
CREATE OR REPLACE FUNCTION increment_post_view_count()
RETURNS TRIGGER AS $$
BEGIN
  -- Only count 'post' content type
  IF NEW.content_type = 'post' THEN
    INSERT INTO post_view_counts (content_id, view_count, last_updated_at)
    VALUES (NEW.content_id, 1, now())
    ON CONFLICT (content_id)
    DO UPDATE SET
      view_count = post_view_counts.view_count + 1,
      last_updated_at = now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Attach trigger to content_interactions
DROP TRIGGER IF EXISTS after_content_interaction_post_view ON content_interactions;
CREATE TRIGGER after_content_interaction_post_view
  AFTER INSERT ON content_interactions
  FOR EACH ROW
  EXECUTE FUNCTION increment_post_view_count();

-- 7. Backfill existing data from content_interactions
INSERT INTO post_view_counts (content_id, view_count, last_updated_at)
SELECT
  content_id,
  COUNT(*) AS view_count,
  MAX(created_at) AS last_updated_at
FROM content_interactions
WHERE content_type = 'post'
GROUP BY content_id
ON CONFLICT (content_id) DO UPDATE
  SET view_count = EXCLUDED.view_count,
      last_updated_at = EXCLUDED.last_updated_at;
