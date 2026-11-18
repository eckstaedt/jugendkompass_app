UPDATE public.editions
SET published_at = COALESCE(published_at, '2020-01-01 12:00:00+00'::timestamptz),
    notification_sent_at = COALESCE(notification_sent_at, '2020-01-01 12:00:00+00'::timestamptz);