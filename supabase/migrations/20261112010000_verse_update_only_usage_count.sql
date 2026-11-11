-- Non-admins may only change usage_count of a verse. The check listed columns
-- one by one and missed the newer ones – among them background_image_url,
-- which the home-screen widgets load. Add them.
create or replace function public.restrict_verse_update_to_usage_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.role() = 'service_role' then return new; end if;
  if public.is_admin(auth.uid()) then return new; end if;
  if new.id is distinct from old.id
     or new.content_id is distinct from old.content_id
     or new.verse is distinct from old.verse
     or new.reference is distinct from old.reference
     or new.date is distinct from old.date
     or new.image_url is distinct from old.image_url
     or new.created_at is distinct from old.created_at
     or new.background_image_url is distinct from old.background_image_url
     or new.image_source_hash is distinct from old.image_source_hash
  then
    raise exception 'Only admins may modify verse fields other than usage_count';
  end if;
  return new;
end;
$$;
