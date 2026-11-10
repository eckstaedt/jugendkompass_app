-- ═══════════════════════════════════════════════════════════════════════════
-- In-App-Popups (Fullscreen), gesteuert über das Admin-Dashboard
--
-- Die App lädt beim Start und bei jeder Rückkehr in den Vordergrund das
-- aktuell aktive Popup (is_active AND starts_at <= now() < ends_at) und zeigt
-- es als Fullscreen-Overlay. Neues Popup = neue Zeile, kein App-Update nötig.
--
--   image_url     optional, https-URL (Bucket "announcements") oder
--                 'asset:assets/images/…' für in der App gebündelte Bilder
--   dismissible   X-Button / "Schließen" anzeigen
--   show_once     nach dem Schließen auf diesem Gerät nicht erneut zeigen
--
-- Übersetzung: automatisch wie bei Ausgaben. Titel/Text werden auf Deutsch
-- gepflegt, der Worker process-translation-jobs schreibt die Übersetzungen
-- nach entity_translations (entity_type 'announcement').
-- Die Spalte translations bleibt als manuelle Überschreibung erhalten
-- ({"en": {"title": "…", "message": "…"}, …}).
-- ═══════════════════════════════════════════════════════════════════════════

create table if not exists public.app_announcements (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  message      text not null,
  image_url    text,
  translations jsonb not null default '{}'::jsonb,
  starts_at    timestamptz not null default now(),
  ends_at      timestamptz not null default (now() + interval '7 days'),
  is_active    boolean not null default true,
  dismissible  boolean not null default true,
  show_once    boolean not null default true,
  created_at   timestamptz not null default now(),
  constraint app_announcements_window check (ends_at > starts_at)
);

create index if not exists app_announcements_window_idx
  on public.app_announcements (starts_at, ends_at)
  where is_active;

alter table public.app_announcements enable row level security;

drop policy if exists "Anyone can read active announcements" on public.app_announcements;
create policy "Anyone can read active announcements"
  on public.app_announcements for select
  to anon, authenticated
  using (is_active or public.is_admin());

drop policy if exists "Admins manage announcements" on public.app_announcements;
create policy "Admins manage announcements"
  on public.app_announcements for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select on public.app_announcements to anon, authenticated;
grant insert, update, delete on public.app_announcements to authenticated;

-- ─── Automatische Übersetzung ───────────────────────────────────────────────

alter table public.translation_jobs
  drop constraint if exists translation_jobs_content_type_check;
alter table public.translation_jobs
  add constraint translation_jobs_content_type_check
  check (content_type in ('post', 'message', 'impulse', 'video', 'verse', 'poll',
                          'edition', 'category', 'announcement'));

alter table public.entity_translations
  drop constraint if exists entity_translations_type_check;
alter table public.entity_translations
  add constraint entity_translations_type_check
  check (entity_type in ('edition', 'category', 'announcement'));

drop trigger if exists trg_translate_announcements on public.app_announcements;
create trigger trg_translate_announcements
after insert or update on public.app_announcements
for each row execute function public.trg_enqueue_translation('announcement', 'title', 'message');

-- Übersetzungen eines gelöschten Popups mit entfernen.
create or replace function public.trg_delete_announcement_translations()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.entity_translations
  where entity_type = 'announcement' and entity_id = old.id::text;
  delete from public.translation_jobs
  where content_type = 'announcement' and record_id = old.id::text;
  return old;
end;
$$;

drop trigger if exists trg_delete_announcement_translations on public.app_announcements;
create trigger trg_delete_announcement_translations
after delete on public.app_announcements
for each row execute function public.trg_delete_announcement_translations();

-- ─── Bilder ─────────────────────────────────────────────────────────────────

insert into storage.buckets (id, name, public)
values ('announcements', 'announcements', true)
on conflict (id) do nothing;

drop policy if exists "Public read announcement images" on storage.objects;
create policy "Public read announcement images"
  on storage.objects for select
  using (bucket_id = 'announcements');

drop policy if exists "Admins upload announcement images" on storage.objects;
create policy "Admins upload announcement images"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'announcements' and public.is_admin());

drop policy if exists "Admins update announcement images" on storage.objects;
create policy "Admins update announcement images"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'announcements' and public.is_admin());

drop policy if exists "Admins delete announcement images" on storage.objects;
create policy "Admins delete announcement images"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'announcements' and public.is_admin());
