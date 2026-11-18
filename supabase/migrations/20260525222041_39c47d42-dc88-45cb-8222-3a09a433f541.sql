ALTER TABLE public.impulses
  ADD COLUMN IF NOT EXISTS notification_title text,
  ADD COLUMN IF NOT EXISTS notification_body text,
  ADD COLUMN IF NOT EXISTS notification_sent_at timestamp with time zone;