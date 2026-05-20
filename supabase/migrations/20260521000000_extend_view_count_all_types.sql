-- Update trigger: remove the 'post'-only filter so ALL content types are counted
-- (impulse, message, video, audio, edition, post, etc.)
CREATE OR REPLACE FUNCTION increment_post_view_count()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO post_view_counts (content_id, view_count, last_updated_at)
  VALUES (NEW.content_id, 1, now())
  ON CONFLICT (content_id)
  DO UPDATE SET
    view_count = post_view_counts.view_count + 1,
    last_updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Backfill all content types from existing interactions (not just posts)
INSERT INTO post_view_counts (content_id, view_count, last_updated_at)
SELECT content_id, COUNT(*) AS view_count, MAX(created_at) AS last_updated_at
FROM content_interactions
GROUP BY content_id
ON CONFLICT (content_id) DO UPDATE
  SET view_count = EXCLUDED.view_count,
      last_updated_at = EXCLUDED.last_updated_at;
