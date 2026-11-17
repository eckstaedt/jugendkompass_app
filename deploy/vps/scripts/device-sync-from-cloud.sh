#!/usr/bin/env bash
# Old app versions (still talking to the Supabase cloud) keep registering push tokens
# and changing their push settings there. This pulls those changes onto the VPS every
# 2 minutes (pg_cron + dblink inside the VPS database). Only rows that CHANGED in the
# cloud since the last run are applied, so devices already on the new app (writing to
# the VPS) are never overwritten by stale cloud rows.
set -euo pipefail
cd /docker/jugendkompass
. scripts/lib.sh
load_config
require CLOUD_DB_URL

echo "--- cloud: allow token registration again (INSERT/UPDATE on device_tokens only)"
psql_cloud </dev/null <<'SQL'
grant insert, update on table public.device_tokens to anon, authenticated;
SQL

echo "--- VPS: sync schema, secret, function"
psql_vps -v url="$CLOUD_DB_URL" </dev/null <<'SQL'
create extension if not exists dblink with schema extensions;
create schema if not exists jk_sync;
revoke all on schema jk_sync from public, anon, authenticated;
create table if not exists jk_sync.device_tokens_seen (device_id text primary key, h text not null);
create table if not exists jk_sync.log (at timestamptz not null default now(), result text);

delete from vault.secrets where name = 'jk_cloud_db_url';
select vault.create_secret(:'url', 'jk_cloud_db_url', 'Cloud DB (read old-app device token changes)') is not null as secret_stored;
SQL

psql_vps </dev/null <<'SQL'
create or replace function jk_sync.device_tokens_hash_sql() returns text language sql immutable as $f$
  select 'md5(row(platform, verse_notifications, content_notifications, notification_hour, notification_minute, fcm_token, language, timezone, user_name, bible_plan_started, bible_plan_notifications_enabled, bible_plan_notification_hour)::text)'
$f$;

create or replace function jk_sync.pull_device_tokens() returns text
language plpgsql security definer set search_path = public, extensions as $f$
declare
  conn text; r record; x public.device_tokens;
  n_upd int := 0; n_ins int := 0; n_del int := 0; n_cloud int;
begin
  select decrypted_secret into conn from vault.decrypted_secrets where name = 'jk_cloud_db_url';
  create temp table _c on commit drop as
    select * from dblink(conn,
      'select device_id, ' || jk_sync.device_tokens_hash_sql() || ', row_to_json(d)::text from public.device_tokens d where device_id is not null')
      as t(device_id text, h text, j text);
  select count(*) into n_cloud from _c;
  if n_cloud = 0 then
    raise exception 'cloud returned no device tokens - refusing to sync';
  end if;

  for r in select c.* from _c c left join jk_sync.device_tokens_seen s using (device_id) where s.h is distinct from c.h loop
    x := json_populate_record(null::public.device_tokens, r.j::json);
    update public.device_tokens d set
      platform = x.platform, verse_notifications = x.verse_notifications,
      content_notifications = x.content_notifications, notification_hour = x.notification_hour,
      notification_minute = x.notification_minute, fcm_token = x.fcm_token, language = x.language,
      timezone = x.timezone, user_name = x.user_name, bible_plan_started = x.bible_plan_started,
      bible_plan_notifications_enabled = x.bible_plan_notifications_enabled,
      bible_plan_notification_hour = x.bible_plan_notification_hour
    where d.device_id = r.device_id;
    if found then
      n_upd := n_upd + 1;
    else
      insert into public.device_tokens (id, device_id, platform, verse_notifications, content_notifications,
        notification_hour, notification_minute, created_at, fcm_token, language, timezone, user_name,
        bible_plan_started, bible_plan_notifications_enabled, bible_plan_notification_hour)
      values (coalesce(x.id, gen_random_uuid()), x.device_id, x.platform, x.verse_notifications, x.content_notifications,
        x.notification_hour, x.notification_minute, coalesce(x.created_at, now()), x.fcm_token, x.language, x.timezone,
        x.user_name, x.bible_plan_started, x.bible_plan_notifications_enabled, x.bible_plan_notification_hour)
      on conflict (id) do nothing;
      n_ins := n_ins + 1;
    end if;
  end loop;

  -- devices the OLD app unregistered in the cloud since the last run
  for r in select s.device_id from jk_sync.device_tokens_seen s
           where not exists (select 1 from _c c where c.device_id = s.device_id) loop
    delete from public.device_tokens where device_id = r.device_id;
    n_del := n_del + 1;
  end loop;

  delete from jk_sync.device_tokens_seen;
  insert into jk_sync.device_tokens_seen select device_id, h from _c;

  insert into jk_sync.log (result) values (format('cloud=%s updated=%s inserted=%s deleted=%s', n_cloud, n_upd, n_ins, n_del));
  delete from jk_sync.log where at < now() - interval '7 days';
  return format('cloud=%s updated=%s inserted=%s deleted=%s', n_cloud, n_upd, n_ins, n_del);
end
$f$;
revoke all on function jk_sync.pull_device_tokens() from public, anon, authenticated;

-- Seed "seen" from the VPS rows (copy of the cloud at cutover + changes made on the VPS),
-- so the first run applies exactly what the old app changed in the cloud since then.
insert into jk_sync.device_tokens_seen (device_id, h)
select device_id, md5(row(platform, verse_notifications, content_notifications, notification_hour, notification_minute,
  fcm_token, language, timezone, user_name, bible_plan_started, bible_plan_notifications_enabled, bible_plan_notification_hour)::text)
from public.device_tokens where device_id is not null
on conflict (device_id) do nothing;
SQL

echo "--- first run:"
psql_vps -At -c "select jk_sync.pull_device_tokens()" </dev/null

echo "--- schedule every 2 minutes:"
psql_vps -At </dev/null <<'SQL'
select cron.unschedule(jobid) from cron.job where jobname = 'jk-sync-device-tokens-from-cloud';
select cron.schedule('jk-sync-device-tokens-from-cloud', '*/2 * * * *', 'select jk_sync.pull_device_tokens()') is not null as scheduled;
SQL
