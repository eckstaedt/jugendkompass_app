-- The app can't update its own device row directly (anon may not read rows,
-- so UPDATE … WHERE device_id = … matches nothing). These functions change
-- exactly one device, identified by its secret random device_id, and only
-- the whitelisted settings.

create or replace function public.update_device_settings(p_device_id text, p_settings jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_device_id is null or length(p_device_id) < 8 then return; end if;
  update public.device_tokens d set
    verse_notifications = coalesce((p_settings ->> 'verse_notifications')::boolean, d.verse_notifications),
    content_notifications = coalesce((p_settings ->> 'content_notifications')::boolean, d.content_notifications),
    notification_hour = coalesce(least(greatest((p_settings ->> 'notification_hour')::int, 0), 23), d.notification_hour),
    notification_minute = coalesce(least(greatest((p_settings ->> 'notification_minute')::int, 0), 59), d.notification_minute),
    language = coalesce(left(p_settings ->> 'language', 8), d.language),
    timezone = coalesce(left(p_settings ->> 'timezone', 64), d.timezone),
    user_name = case when p_settings ? 'user_name' then left(p_settings ->> 'user_name', 80) else d.user_name end,
    bible_plan_started = coalesce((p_settings ->> 'bible_plan_started')::boolean, d.bible_plan_started),
    bible_plan_notifications_enabled = coalesce((p_settings ->> 'bible_plan_notifications_enabled')::boolean, d.bible_plan_notifications_enabled),
    bible_plan_notification_hour = coalesce(least(greatest((p_settings ->> 'bible_plan_notification_hour')::int, 0), 23), d.bible_plan_notification_hour)
  where d.device_id = p_device_id;
end;
$$;

create or replace function public.unregister_device(p_device_id text)
returns void language sql security definer set search_path = public as $$
  delete from public.device_tokens where device_id = p_device_id and length(p_device_id) >= 8;
$$;

revoke all on function public.update_device_settings(text, jsonb) from public;
revoke all on function public.unregister_device(text) from public;
grant execute on function public.update_device_settings(text, jsonb) to anon, authenticated;
grant execute on function public.unregister_device(text) to anon, authenticated;
