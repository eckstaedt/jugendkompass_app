-- ═══════════════════════════════════════════════════════════════════════════
-- In-App-Meldungen (Fullscreen), ferngesteuert über Supabase
--
-- Die App lädt beim Start und bei jeder Rückkehr in den Vordergrund die
-- aktuell aktive Meldung (is_active AND starts_at <= now() < ends_at) und
-- zeigt sie als Fullscreen-Overlay. Neue Meldungen = neue Zeile, kein
-- App-Update nötig.
--
--   image_url     'asset:assets/images/…' (in der App gebündelt) oder https-URL
--   translations  {"en": {"title": "…", "message": "…"}, "ru": {…}, …}
--                 Fallback ist der deutsche title/message.
--   dismissible   X-Button anzeigen
--   show_once     nach dem Wegklicken auf diesem Gerät nicht erneut zeigen
-- ═══════════════════════════════════════════════════════════════════════════

create table if not exists public.app_announcements (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  message      text not null,
  image_url    text,
  translations jsonb not null default '{}'::jsonb,
  starts_at    timestamptz not null,
  ends_at      timestamptz not null,
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
  using (is_active);

drop policy if exists "Admins manage announcements" on public.app_announcements;
create policy "Admins manage announcements"
  on public.app_announcements for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select on public.app_announcements to anon, authenticated;

-- Wartungsarbeiten 09.11.2026 18:00 – 10.11.2026 18:00 (Europe/Berlin).
-- Wird bereits ab dem 09.11. 00:00 angezeigt, damit Nutzer vorab informiert sind.
insert into public.app_announcements
  (title, message, image_url, translations, starts_at, ends_at)
values (
  'Wartungsarbeiten',
  'Aufgrund von Wartungsarbeiten kann es zwischen dem 09.11. um 18 Uhr und dem 10.11. um 18 Uhr zu Verzögerungen oder Einschränkungen kommen. Die App läuft trotzdem weiter – danke für deine Geduld!',
  'asset:assets/images/maintenance.jpg',
  jsonb_build_object(
    'en', jsonb_build_object(
      'title', 'Maintenance',
      'message', 'Due to maintenance work, there may be delays or limitations between Nov 9 at 6 pm and Nov 10 at 6 pm. The app keeps running – thanks for your patience!'),
    'ru', jsonb_build_object(
      'title', 'Технические работы',
      'message', 'Из-за технических работ с 9.11 18:00 до 10.11 18:00 возможны задержки или ограничения. Приложение продолжает работать – спасибо за терпение!'),
    'es', jsonb_build_object(
      'title', 'Mantenimiento',
      'message', 'Debido a trabajos de mantenimiento, puede haber retrasos o limitaciones entre el 9/11 a las 18:00 y el 10/11 a las 18:00. La app sigue funcionando – ¡gracias por tu paciencia!'),
    'pl', jsonb_build_object(
      'title', 'Prace konserwacyjne',
      'message', 'Z powodu prac konserwacyjnych między 9.11 godz. 18:00 a 10.11 godz. 18:00 mogą wystąpić opóźnienia lub ograniczenia. Aplikacja nadal działa – dziękujemy za cierpliwość!'),
    'tr', jsonb_build_object(
      'title', 'Bakım çalışmaları',
      'message', 'Bakım çalışmaları nedeniyle 09.11 saat 18:00 ile 10.11 saat 18:00 arasında gecikmeler veya kısıtlamalar olabilir. Uygulama çalışmaya devam ediyor – sabrın için teşekkürler!'),
    'he', jsonb_build_object(
      'title', 'עבודות תחזוקה',
      'message', 'עקב עבודות תחזוקה ייתכנו עיכובים או הגבלות בין 9.11 בשעה 18:00 ל-10.11 בשעה 18:00. האפליקציה ממשיכה לפעול – תודה על הסבלנות!')
  ),
  timestamptz '2026-11-09 00:00:00 Europe/Berlin',
  timestamptz '2026-11-10 18:00:00 Europe/Berlin'
);
