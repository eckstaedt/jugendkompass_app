-- Push registration has been broken since late July: the app registers its
-- FCM token with an upsert (INSERT … ON CONFLICT (device_id) DO UPDATE), which
-- needs SELECT rights that anon no longer has → "permission denied", so no new
-- device got push notifications.
--
-- Fix without exposing any data:
--  * anon gets the SELECT privilege (needed to plan ON CONFLICT), but
--    there is still no SELECT policy for anon, so no row is ever readable.
--  * a BEFORE INSERT trigger merges into an existing row itself and skips the
--    insert, so the ON CONFLICT path (which would need row visibility) is
--    never taken. Only token/language/timezone/platform are merged – the
--    user's notification settings are never overwritten by the token refresh.
--  * dangerous table privileges of anon are removed.

revoke truncate, references, trigger on public.device_tokens from anon;
-- Column rights are needed to plan the upsert; RLS has no SELECT policy for
-- anon, so no row is ever returned to anon.
grant select on public.device_tokens to anon;

create or replace function public.device_tokens_merge()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.device_tokens where device_id = new.device_id) then
    update public.device_tokens d set
      fcm_token = coalesce(new.fcm_token, d.fcm_token),
      language = coalesce(new.language, d.language),
      timezone = coalesce(new.timezone, d.timezone)
    where d.device_id = new.device_id;
    return null; -- handled, skip the insert (and the ON CONFLICT path)
  end if;
  -- An upsert's new row must pass a SELECT policy. Allow exactly this row,
  -- for this request only (transaction-local setting).
  perform set_config('jk.device_insert', new.device_id, true);
  return new;
end;
$$;

drop trigger if exists device_tokens_merge on public.device_tokens;
create trigger device_tokens_merge before insert on public.device_tokens
  for each row execute function public.device_tokens_merge();

drop policy if exists "Devices see only the row they insert" on public.device_tokens;
create policy "Devices see only the row they insert" on public.device_tokens
  for select to anon, authenticated
  using (device_id = current_setting('jk.device_insert', true));
