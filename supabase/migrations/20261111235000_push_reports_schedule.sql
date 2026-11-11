-- Verse of the day report: posted at 07:00 (post_after), shows how many
-- devices still get the verse later today at their own time.
alter table public.push_reports add column if not exists post_after timestamptz;
alter table public.push_reports add column if not exists scheduled_later int;
