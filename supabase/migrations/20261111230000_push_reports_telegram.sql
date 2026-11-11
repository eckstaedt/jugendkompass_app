-- Push reports for the Telegram bot: every push (or daily push group) is one
-- row; taps in the app are counted in push_opens. The bot posts a message per
-- report to every subscriber and keeps it up to date.

create table if not exists public.push_reports (
  id uuid primary key default gen_random_uuid(),
  report_key text unique,             -- e.g. 'verse:2026-11-12' (hourly runs add up)
  category text not null,             -- Vers des Tages, Impuls, Artikel …
  title text,
  sent int not null default 0,        -- accepted by FCM
  failed int not null default 0,
  opens int not null default 0,       -- cached count of push_opens
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.push_opens (
  push_id uuid not null references public.push_reports(id) on delete cascade,
  device_id text not null,
  opened_at timestamptz not null default now(),
  primary key (push_id, device_id)
);

create table if not exists public.telegram_subscribers (
  chat_id bigint primary key,
  name text,
  subscribed_at timestamptz not null default now()
);

create table if not exists public.telegram_push_messages (
  push_id uuid not null references public.push_reports(id) on delete cascade,
  chat_id bigint not null,
  message_id bigint not null,
  last_text text,
  primary key (push_id, chat_id)
);

alter table public.push_reports enable row level security;
alter table public.push_opens enable row level security;
alter table public.telegram_subscribers enable row level security;
alter table public.telegram_push_messages enable row level security;

drop policy if exists "push reports admin read" on public.push_reports;
create policy "push reports admin read" on public.push_reports for select using (public.is_admin());

-- Called by the app when a push is tapped (counted once per device).
create or replace function public.log_push_open(p_push_id uuid, p_device_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_push_id is null or p_device_id is null or length(p_device_id) < 8 then return; end if;
  insert into public.push_opens (push_id, device_id) values (p_push_id, p_device_id)
  on conflict do nothing;
  if found then
    update public.push_reports set opens = opens + 1, updated_at = now() where id = p_push_id;
  end if;
exception when foreign_key_violation then
  null; -- unknown push id
end;
$$;
revoke all on function public.log_push_open(uuid, text) from public;
grant execute on function public.log_push_open(uuid, text) to anon, authenticated;

-- Hourly push runs (verse of the day, bible plan) add up into one report.
create or replace function public.add_push_report_counts(p_id uuid, p_sent int, p_failed int)
returns void language sql security definer set search_path = public as $$
  update public.push_reports set sent = sent + p_sent, failed = failed + p_failed, updated_at = now()
  where id = p_id;
$$;
revoke all on function public.add_push_report_counts(uuid, int, int) from public, anon, authenticated;
