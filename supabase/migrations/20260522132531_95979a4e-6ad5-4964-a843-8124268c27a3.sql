CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'check-tomorrow-verse-daily') THEN
    PERFORM cron.unschedule('check-tomorrow-verse-daily');
  END IF;
END $$;

SELECT cron.schedule(
  'check-tomorrow-verse-daily',
  '0 9 * * *',
  $$
  SELECT net.http_post(
    url := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/check-tomorrow-verse',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkY2RpYnZjbGF1bHF4Zmp5enBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0NTkxODksImV4cCI6MjA4MTAzNTE4OX0.cuJ5OKNauU_-mKQ3oX8Yi88kEJq2o5fpADlYquAkZLw'
    ),
    body := '{}'::jsonb
  ) AS request_id;
  $$
);