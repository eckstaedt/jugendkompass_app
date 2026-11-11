-- messages use integer ids: entity_id must be text, otherwise the trigger
-- breaks inserting short messages.
alter table public.image_translations alter column entity_id type text using entity_id::text;

drop function if exists public.enqueue_image_translation(text, text, uuid, text);
create or replace function public.enqueue_image_translation(
  p_url text, p_entity_type text, p_entity_id text, p_title text
) returns void language sql security definer set search_path = public as $$
  insert into public.image_translations (source_url, language, entity_type, entity_id, title)
  select p_url, l, p_entity_type, p_entity_id, p_title
  from unnest(array['en', 'ru', 'es', 'pl', 'tr', 'he']) as l
  where p_url is not null and p_url like 'http%'
  on conflict (source_url, language) do nothing;
$$;
revoke all on function public.enqueue_image_translation(text, text, text, text) from public, anon, authenticated;

create or replace function public.queue_image_translation_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.image_url is null or new.image_url = '' then return new; end if;
  if tg_op = 'UPDATE' and new.image_url is not distinct from old.image_url then return new; end if;
  begin
    perform public.enqueue_image_translation(new.image_url, tg_table_name, new.id::text,
      coalesce(to_jsonb(new) ->> 'title', to_jsonb(new) ->> 'name', ''));
  exception when others then
    raise warning 'image translation queue failed: %', sqlerrm; -- never block saving content
  end;
  return new;
end;
$$;

create or replace function public.enqueue_all_image_translations()
returns int language plpgsql security definer set search_path = public as $$
declare
  before_count int;
  after_count int;
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  select count(*) into before_count from public.image_translations;
  perform public.enqueue_image_translation(image_url, 'posts', id::text, title) from public.posts;
  perform public.enqueue_image_translation(image_url, 'impulses', id::text, title) from public.impulses;
  perform public.enqueue_image_translation(image_url, 'editions', id::text, coalesce(title, name)) from public.editions;
  perform public.enqueue_image_translation(image_url, 'messages', id::text, title) from public.messages;
  select count(*) into after_count from public.image_translations;
  return after_count - before_count;
end;
$$;
