-- Schedule translation worker to run automatically every 5 minutes

select cron.unschedule(jobid)
from cron.job
where jobname = 'process_translation_jobs';

select cron.schedule(
  'process_translation_jobs',
  '*/5 * * * *',
  $$
  select net.http_post(
    url := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/process-translation-jobs',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', '__ANON_KEY__',
      'Authorization', 'Bearer __ANON_KEY__'
    ),
    body := '{"batchSize":1,"geminiApiKey":"__GEMINI_API_KEY__"}'::jsonb
  );
  $$
);
