-- Merge release_date into published_at (timestamptz, supports time of day)
UPDATE public.editions
SET published_at = (release_date::timestamp AT TIME ZONE 'Europe/Berlin')
WHERE release_date IS NOT NULL
  AND published_at IS NULL;

ALTER TABLE public.editions DROP COLUMN IF EXISTS release_date;