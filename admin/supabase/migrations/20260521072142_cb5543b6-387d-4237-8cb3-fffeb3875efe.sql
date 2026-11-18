ALTER TABLE public.editions
  ADD COLUMN IF NOT EXISTS notification_title text,
  ADD COLUMN IF NOT EXISTS notification_body text,
  ADD COLUMN IF NOT EXISTS notification_sent_at timestamptz;

CREATE INDEX IF NOT EXISTS idx_editions_pending_push
  ON public.editions (published_at)
  WHERE notification_sent_at IS NULL AND notification_title IS NOT NULL;