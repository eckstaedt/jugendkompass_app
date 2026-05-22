-- SQL script to fix poll vote counts
-- This script will recalculate the vote counts for all poll options based on actual votes in poll_votes table

-- First, let's see the current state (for verification)
-- Uncomment to check current counts vs actual votes:
/*
SELECT
  po.id as option_id,
  po.option_text,
  po.votes as current_count,
  COUNT(pv.id) as actual_count,
  (po.votes - COUNT(pv.id)) as difference
FROM poll_options po
LEFT JOIN poll_votes pv ON pv.option_id = po.id
GROUP BY po.id, po.option_text, po.votes
HAVING po.votes != COUNT(pv.id)
ORDER BY difference DESC;
*/

-- Fix all vote counts by setting them to the actual count from poll_votes
UPDATE poll_options
SET votes = (
  SELECT COUNT(*)
  FROM poll_votes
  WHERE poll_votes.option_id = poll_options.id
);

-- Verify the fix (should return no rows if all counts are correct)
SELECT
  po.id as option_id,
  po.option_text,
  po.votes as updated_count,
  COUNT(pv.id) as actual_count,
  (po.votes - COUNT(pv.id)) as difference
FROM poll_options po
LEFT JOIN poll_votes pv ON pv.option_id = po.id
GROUP BY po.id, po.option_text, po.votes
HAVING po.votes != COUNT(pv.id);
