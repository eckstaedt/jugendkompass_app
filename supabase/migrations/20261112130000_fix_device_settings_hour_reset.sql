-- Fix: greatest(NULL, 0) is 0, so every settings update WITHOUT an hour reset
-- notification_hour to 0. Only change a value when the key is sent.
create or replace function public.update_device_settings(p_device_id text, p_settings jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_device_id is null or length(p_device_id) < 8 then return; end if;
  update public.device_tokens d set
    verse_notifications = coalesce((p_settings ->> 'verse_notifications')::boolean, d.verse_notifications),
    content_notifications = coalesce((p_settings ->> 'content_notifications')::boolean, d.content_notifications),
    notification_hour = case when p_settings ? 'notification_hour' then least(greatest((p_settings ->> 'notification_hour')::int, 0), 23) else d.notification_hour end,
    notification_minute = case when p_settings ? 'notification_minute' then least(greatest((p_settings ->> 'notification_minute')::int, 0), 59) else d.notification_minute end,
    language = coalesce(left(p_settings ->> 'language', 8), d.language),
    timezone = coalesce(left(p_settings ->> 'timezone', 64), d.timezone),
    user_name = case when p_settings ? 'user_name' then left(p_settings ->> 'user_name', 80) else d.user_name end,
    bible_plan_started = coalesce((p_settings ->> 'bible_plan_started')::boolean, d.bible_plan_started),
    bible_plan_notifications_enabled = coalesce((p_settings ->> 'bible_plan_notifications_enabled')::boolean, d.bible_plan_notifications_enabled),
    bible_plan_notification_hour = case when p_settings ? 'bible_plan_notification_hour' then least(greatest((p_settings ->> 'bible_plan_notification_hour')::int, 0), 23) else d.bible_plan_notification_hour end
  where d.device_id = p_device_id;
end;
$$;

