-- Migration: Track how often the verse of the day is shared/saved.
-- A single counter is incremented for both share-sheet and save-to-gallery actions.

-- 1. Add usage_count column
ALTER TABLE verse_of_the_day
  ADD COLUMN IF NOT EXISTS usage_count integer NOT NULL DEFAULT 0;

-- 2. RPC to atomically increment the counter from the client.
--    SECURITY DEFINER lets non-admin users update the counter despite RLS.
CREATE OR REPLACE FUNCTION increment_verse_usage(verse_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE verse_of_the_day
  SET usage_count = usage_count + 1
  WHERE id = verse_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Allow anonymous + authenticated callers to invoke the RPC.
GRANT EXECUTE ON FUNCTION increment_verse_usage(uuid) TO anon, authenticated;
