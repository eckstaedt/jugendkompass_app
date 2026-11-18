select cron.alter_job(
  job_id := 5,
  command := $$
  SELECT net.http_post(
    url := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/dispatch-edition-pushes',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkY2RpYnZjbGF1bHF4Zmp5enBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTQ1OTE4OSwiZXhwIjoyMDgxMDM1MTg5fQ.I29tT_hib4cHHfwY-Iep_lA9iSBjP0UL7xKNUb1TDyQ'
    ),
    body := '{}'::jsonb
  );
  $$
);