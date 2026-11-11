-- AI translation of the text on cover images (posts, impulses, editions,
-- short messages). A GitHub Actions worker (tool/image_translate) scans each
-- image once for text and creates one edited copy per language with Gemini.
-- The app swaps the image URL by language (ImageLocalizer).

create table if not exists public.image_text_scans (
  source_url text primary key,
  has_text boolean not null,
  detected_text text,
  scanned_at timestamptz not null default now()
);

create table if not exists public.image_translations (
  id uuid primary key default gen_random_uuid(),
  source_url text not null,
  language text not null,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'completed', 'no_text', 'failed', 'rejected')),
  url text,
  storage_path text,
  entity_type text,
  entity_id uuid,
  title text,
  error text,
  attempts int not null default 0,
  force boolean not null default false,
  requested_at timestamptz not null default now(),
  started_at timestamptz,
  finished_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (source_url, language)
);

create index if not exists image_translations_status_idx on public.image_translations (status);

-- Worker heartbeat / state shown in the translation panel
-- ("waiting for credit", "API key missing" …).
create table if not exists public.worker_status (
  name text primary key,
  state text not null,
  message text,
  updated_at timestamptz not null default now()
);

alter table public.image_text_scans enable row level security;
alter table public.image_translations enable row level security;
alter table public.worker_status enable row level security;

drop policy if exists "image translations readable" on public.image_translations;
create policy "image translations readable" on public.image_translations
  for select using (status = 'completed' or public.is_admin());
drop policy if exists "image translations admin" on public.image_translations;
create policy "image translations admin" on public.image_translations
  for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "image scans admin" on public.image_text_scans;
create policy "image scans admin" on public.image_text_scans
  for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "worker status admin" on public.worker_status;
create policy "worker status admin" on public.worker_status
  for all using (public.is_admin()) with check (public.is_admin());

-- Queue all target languages for one image.
create or replace function public.enqueue_image_translation(
  p_url text, p_entity_type text, p_entity_id uuid, p_title text
) returns void language sql security definer set search_path = public as $$
  insert into public.image_translations (source_url, language, entity_type, entity_id, title)
  select p_url, l, p_entity_type, p_entity_id, p_title
  from unnest(array['en', 'ru', 'es', 'pl', 'tr', 'he']) as l
  where p_url is not null and p_url like 'http%'
  on conflict (source_url, language) do nothing;
$$;
revoke all on function public.enqueue_image_translation(text, text, uuid, text) from public, anon, authenticated;

-- New / changed images are queued automatically.
create or replace function public.queue_image_translation_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  t text;
begin
  if new.image_url is null or new.image_url = '' then return new; end if;
  if tg_op = 'UPDATE' and new.image_url is not distinct from old.image_url then return new; end if;
  t := coalesce(to_jsonb(new) ->> 'title', to_jsonb(new) ->> 'name', '');
  perform public.enqueue_image_translation(new.image_url, tg_table_name, new.id, t);
  return new;
end;
$$;

do $$
declare tbl text;
begin
  foreach tbl in array array['posts', 'impulses', 'editions', 'messages'] loop
    execute format('drop trigger if exists queue_image_translation on public.%I', tbl);
    execute format(
      'create trigger queue_image_translation after insert or update of image_url on public.%I
       for each row execute function public.queue_image_translation_trigger()', tbl);
  end loop;
end $$;

-- Panel button: queue every existing image (admins only).
create or replace function public.enqueue_all_image_translations()
returns int language plpgsql security definer set search_path = public as $$
declare
  before_count int;
  after_count int;
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  select count(*) into before_count from public.image_translations;
  perform public.enqueue_image_translation(image_url, 'posts', id, title) from public.posts;
  perform public.enqueue_image_translation(image_url, 'impulses', id, title) from public.impulses;
  perform public.enqueue_image_translation(image_url, 'editions', id, coalesce(title, name)) from public.editions;
  perform public.enqueue_image_translation(image_url, 'messages', id, title) from public.messages;
  select count(*) into after_count from public.image_translations;
  return after_count - before_count;
end;
$$;
grant execute on function public.enqueue_all_image_translations() to authenticated;
