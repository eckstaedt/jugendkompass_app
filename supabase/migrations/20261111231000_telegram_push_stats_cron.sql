-- Refresh the tap counters in the Telegram push statistics every 5 minutes.
select cron.unschedule('telegram-push-stats-refresh') where exists (select 1 from cron.job where jobname = 'telegram-push-stats-refresh');
select cron.schedule('telegram-push-stats-refresh', '*/5 * * * *', $$
  select net.http_post(
    url := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/telegram-push-bot',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object('action', 'refresh'));
$$);
