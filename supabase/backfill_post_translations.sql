-- Backfill missing translations for existing articles (posts)
-- 1) Queue jobs for all posts that are missing at least one active target translation
select public.enqueue_translation_backfill_for_posts(100000);

-- 2) Process jobs in batches by invoking the edge function
-- Use Dashboard or CLI invoke repeatedly until `No pending translation jobs`.
-- Example payload:
-- {
--   "batchSize": 50
-- }
