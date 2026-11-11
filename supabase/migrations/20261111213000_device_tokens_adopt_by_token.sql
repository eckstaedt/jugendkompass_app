-- A device that registers with a new device_id but a known FCM token is the
-- same phone: take over the existing row (keeps its notification settings)
-- instead of inserting a fresh row with defaults (the dedupe trigger would
-- then delete the old row and its settings).
create or replace function public.device_tokens_merge()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.device_tokens where device_id = new.device_id) then
    update public.device_tokens d set
      fcm_token = coalesce(new.fcm_token, d.fcm_token),
      language = coalesce(new.language, d.language),
      timezone = coalesce(new.timezone, d.timezone)
    where d.device_id = new.device_id;
    return null;
  end if;
  if new.fcm_token is not null
     and exists (select 1 from public.device_tokens where fcm_token = new.fcm_token) then
    update public.device_tokens d set
      device_id = new.device_id,
      language = coalesce(new.language, d.language),
      timezone = coalesce(new.timezone, d.timezone)
    where d.fcm_token = new.fcm_token;
    return null;
  end if;
  perform set_config('jk.device_insert', new.device_id, true);
  return new;
end;
$$;
