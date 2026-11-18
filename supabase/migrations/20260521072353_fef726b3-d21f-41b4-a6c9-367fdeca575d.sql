CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Vorherigen Job entfernen, falls vorhanden
DO $$
DECLARE
  jid bigint;
BEGIN
  SELECT jobid INTO jid FROM cron.job WHERE jobname = 'dispatch-edition-pushes-every-minute';
  IF jid IS NOT NULL THEN
    PERFORM cron.unschedule(jid);
  END IF;
END $$;

SELECT cron.schedule(
  'dispatch-edition-pushes-every-minute',
  '* * * * *',
  $$
  SELECT net.http_post(
    url := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/dispatch-edition-pushes',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkY2RpYnZjbGF1bHF4Zmp5enBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0NTkxODksImV4cCI6MjA4MTAzNTE4OX0.cuJ5OKNauU_-mKQ3oX8Yi88kEJq2o5fpADlYquAkZLw'
    ),
    body := jsonb_build_object('source', 'cron', 'time', now())
  );
  $$
);