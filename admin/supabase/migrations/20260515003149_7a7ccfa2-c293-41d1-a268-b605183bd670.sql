create extension if not exists pg_cron;
create extension if not exists pg_net;

do $$
begin
  if exists (select 1 from cron.job where jobname = 'daily-stats-telegram') then
    perform cron.unschedule('daily-stats-telegram');
  end if;
end $$;

select cron.schedule(
  'daily-stats-telegram',
  '0 * * * *',
  $cron$
  select net.http_post(
    url := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/daily-stats-telegram',
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'Authorization','Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkY2RpYnZjbGF1bHF4Zmp5enBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0NTkxODksImV4cCI6MjA4MTAzNTE4OX0.cuJ5OKNauU_-mKQ3oX8Yi88kEJq2o5fpADlYquAkZLw'
    ),
    body := '{}'::jsonb
  );
  $cron$
);