-- status.jugendkompass.com: data for the admin status dashboard.
-- public.status_dashboard() returns one JSON document; only admins (public.is_admin) get data.
create schema if not exists jk_status;
revoke all on schema jk_status from public, anon, authenticated;

-- Host disk usage, sampled by pg_cron (the DB data dir lives on the host disk).
create table if not exists jk_status.disk (at timestamptz primary key default now(), total bigint, used bigint, avail bigint);
create or replace function jk_status.sample_disk() returns void language plpgsql security definer as $f$
declare l text; p text[];
begin
  create temp table if not exists _df (line text) on commit drop;
  copy _df from program 'df -B1 /var/lib/postgresql/data | tail -1';
  select line into l from _df limit 1;
  p := regexp_split_to_array(trim(l), '\s+');
  insert into jk_status.disk (total, used, avail) values (p[2]::bigint, p[3]::bigint, p[4]::bigint);
  delete from jk_status.disk where at < now() - interval '30 days';
end $f$;
select jk_status.sample_disk();
select cron.unschedule(jobid) from cron.job where jobname = 'jk-status-disk';
select cron.schedule('jk-status-disk', '*/10 * * * *', 'select jk_status.sample_disk()');

-- Free-form notes shown on the dashboard (e.g. last offline backup).
create table if not exists jk_status.notes (key text primary key, value text, updated_at timestamptz default now());
insert into jk_status.notes (key, value) values
  ('offline_backup', 'USB-Stick "JUKO BACKUP" – 17.11.2026 (6.356 Dateien + Datenbank)')
on conflict (key) do nothing;

create or replace function public.status_dashboard() returns jsonb
language plpgsql stable security definer set search_path = public, extensions as $f$
declare res jsonb;
begin
  if not coalesce(public.is_admin(auth.uid()), false) then
    raise exception 'Nur für Admins' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'generated_at', now(),

    'database', jsonb_build_object(
      'size_bytes', pg_database_size(current_database()),
      'connections', (select count(*) from pg_stat_activity where datname = current_database()),
      'version', current_setting('server_version')),

    'disk', (select to_jsonb(d) from jk_status.disk d order by at desc limit 1),

    'storage', (select coalesce(jsonb_agg(jsonb_build_object('bucket', bucket_id, 'files', n, 'bytes', b) order by b desc), '[]')
                from (select bucket_id, count(*) n, coalesce(sum((metadata->>'size')::bigint), 0) b from storage.objects group by 1) s),

    'devices', jsonb_build_object(
      'total', (select count(*) from device_tokens where fcm_token is not null),
      'content_on', (select count(*) from device_tokens where fcm_token is not null and content_notifications),
      'verse_on', (select count(*) from device_tokens where fcm_token is not null and verse_notifications),
      'by_platform', (select coalesce(jsonb_object_agg(coalesce(platform, '?'), n), '{}') from (select platform, count(*) n from device_tokens where fcm_token is not null group by 1) x),
      'by_language', (select coalesce(jsonb_object_agg(coalesce(language, '?'), n), '{}') from (select language, count(*) n from device_tokens where fcm_token is not null group by 1) x),
      'verse_hours', (select coalesce(jsonb_object_agg(h, n), '{}') from (select lpad(notification_hour::text, 2, '0') h, count(*) n from device_tokens where fcm_token is not null and verse_notifications group by 1) x)),

    'activity', jsonb_build_object(
      'active_24h', (select count(distinct device_id) from content_interactions where created_at > now() - interval '24 hours'),
      'active_7d', (select count(distinct device_id) from content_interactions where created_at > now() - interval '7 days'),
      'views_24h', (select count(*) from content_interactions where created_at > now() - interval '24 hours'),
      'top_24h', (select coalesce(jsonb_agg(jsonb_build_object('title', t, 'type', ct, 'views', n) order by n desc), '[]') from (
                    select coalesce(content_title, content_id) t, content_type ct, count(*) n from content_interactions
                    where created_at > now() - interval '24 hours' group by 1, 2 order by 3 desc limit 8) x)),

    'versions', jsonb_build_object(
      -- latest version per device seen in the last 30 days
      'current', (select coalesce(jsonb_agg(jsonb_build_object('version', v, 'devices', n) order by n desc), '[]') from (
                    select v, count(*) n from (
                      select distinct on (device_id) device_id, app_version v from content_interactions
                      where created_at > now() - interval '30 days' and app_version is not null and device_id is not null
                      order by device_id, created_at desc) d group by 1) x),
      -- devices first seen on 2.3.7, per hour (cumulative is computed in the page)
      'adoption_237', (select coalesce(jsonb_agg(jsonb_build_object('hour', h, 'new', n) order by h), '[]') from (
                    select date_trunc('hour', first_seen) h, count(*) n from (
                      select device_id, min(created_at) first_seen from content_interactions
                      where app_version like '2.3.7%' and device_id is not null group by 1) f group by 1) x)),

    'pushes', (select coalesce(jsonb_agg(to_jsonb(p) order by p.created_at desc), '[]') from (
                 select id, category, title, sent, failed, opens, scheduled_later, created_at from push_reports
                 order by created_at desc limit 40) p),

    'cron', (select coalesce(jsonb_agg(x order by x->>'name'), '[]') from (
               select jsonb_build_object(
                 'name', j.jobname, 'schedule', j.schedule, 'active', j.active,
                 'last_run', (select max(start_time) from cron.job_run_details d where d.jobid = j.jobid),
                 'last_status', (select status from cron.job_run_details d where d.jobid = j.jobid order by start_time desc limit 1),
                 'runs_24h', (select count(*) from cron.job_run_details d where d.jobid = j.jobid and start_time > now() - interval '24 hours'),
                 'failed_24h', (select count(*) from cron.job_run_details d where d.jobid = j.jobid and start_time > now() - interval '24 hours' and status <> 'succeeded'),
                 'last_error', (select left(return_message, 200) from cron.job_run_details d where d.jobid = j.jobid and status <> 'succeeded' order by start_time desc limit 1)
               ) x from cron.job j) c),

    'http', jsonb_build_object(
      'last_hour', (select coalesce(jsonb_object_agg(k, n), '{}') from (
                      select coalesce(status_code::text, 'Fehler') k, count(*) n from net._http_response
                      where created > now() - interval '1 hour' group by 1) x),
      'last_errors', (select coalesce(jsonb_agg(jsonb_build_object('at', created, 'status', status_code, 'msg', left(coalesce(error_msg, content), 160)) order by created desc), '[]') from (
                      select created, status_code, error_msg, content from net._http_response
                      where created > now() - interval '24 hours' and (status_code is null or status_code >= 400)
                      order by created desc limit 8) e)),

    'sync', jsonb_build_object(
      'last_device', (select to_jsonb(l) from jk_sync.log l where result like 'cloud=%' order by at desc limit 1),
      'last_content', (select to_jsonb(l) from jk_sync.log l where result like 'content%' order by at desc limit 1),
      'last_changes', (select coalesce(jsonb_agg(to_jsonb(l) order by l.at desc), '[]') from (
                        select at, result from jk_sync.log
                        where result not like '%no changes%' and result not like '%updated=0 inserted=0 deleted=0'
                        order by at desc limit 10) l)),

    'translations', jsonb_build_object(
      'by_status', (select coalesce(jsonb_object_agg(coalesce(status, '?'), n), '{}') from (select status, count(*) n from translation_jobs group by 1) x),
      'last_completed', (select max(completed_at) from translation_jobs where status = 'completed'),
      'last_errors', (select coalesce(jsonb_agg(jsonb_build_object('type', content_type, 'at', updated_at, 'error', left(last_error, 160)) order by updated_at desc), '[]') from (
                        select content_type, updated_at, last_error from translation_jobs where status = 'failed' order by updated_at desc limit 5) e),
      'workers', (select coalesce(jsonb_agg(to_jsonb(w)), '[]') from worker_status w)),

    'content', jsonb_build_object(
      'counts', jsonb_build_object(
        'posts', (select count(*) from posts), 'impulses', (select count(*) from impulses),
        'messages', (select count(*) from messages), 'videos', (select count(*) from videos),
        'editions', (select count(*) from editions), 'polls', (select count(*) from polls)),
      'verse_planned_until', (select max(date) from verse_of_the_day),
      'verse_days_ahead', (select max(date) - current_date from verse_of_the_day),
      'verse_today', (select jsonb_build_object('reference', reference, 'has_image', image_url is not null) from verse_of_the_day where date = current_date limit 1),
      'latest', (select coalesce(jsonb_agg(x order by (x->>'at') desc), '[]') from (
                   (select jsonb_build_object('type', 'Beitrag', 'title', title, 'at', created_at) x from posts order by created_at desc limit 4)
                   union all (select jsonb_build_object('type', 'Impuls', 'title', title, 'at', created_at) from impulses order by created_at desc limit 3)
                   union all (select jsonb_build_object('type', 'Kurznachricht', 'title', title, 'at', created_at) from messages order by created_at desc limit 3)
                   union all (select jsonb_build_object('type', 'Video', 'title', title, 'at', created_at) from videos order by created_at desc limit 3)) l),
      'announcements_active', (select count(*) from app_announcements where coalesce(is_active, true) and now() between coalesce(starts_at, '-infinity') and coalesce(ends_at, 'infinity'))),

    'auth', jsonb_build_object(
      'users_total', (select count(*) from auth.users),
      'anonymous', (select count(*) from auth.users where is_anonymous),
      'new_24h', (select count(*) from auth.users where created_at > now() - interval '24 hours'),
      'admins', (select count(*) from public.users where role = 'admin'),
      'admin_logins_7d', (select count(*) from auth.users a join public.users u on u.id = a.id where u.role = 'admin' and a.last_sign_in_at > now() - interval '7 days')),

    'telegram', jsonb_build_object(
      'subscribers', (select count(*) from telegram_subscribers),
      'messages_7d', (select count(*) from telegram_push_messages tm join push_reports p on p.id = tm.push_id where p.created_at > now() - interval '7 days')),

    'notes', (select coalesce(jsonb_object_agg(key, value), '{}') from jk_status.notes)
  ) into res;
  return res;
end $f$;

revoke all on function public.status_dashboard() from public, anon;
grant execute on function public.status_dashboard() to authenticated;
notify pgrst, 'reload schema';
