-- Open rate is reported once, 12 h after sending.
alter table public.push_reports add column if not exists opens_reported_at timestamptz;
