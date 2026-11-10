-- Status of the AI voice versions (tool/tts/generate_english_audio.py) so the
-- translation panel can show running / waiting / failed jobs and restart them.
create table if not exists public.audio_tts_jobs (
  audio_id         uuid not null references public.audios(id) on delete cascade,
  language         text not null,
  status           text not null default 'pending'
                   check (status in ('pending', 'processing', 'completed', 'failed', 'skipped')),
  force            boolean not null default false,   -- regenerate even if up to date
  attempts         integer not null default 0,
  error            text,
  worker           text,
  text_digest      text,
  duration_seconds numeric,
  requested_at     timestamptz not null default now(),
  started_at       timestamptz,
  finished_at      timestamptz,
  updated_at       timestamptz not null default now(),
  primary key (audio_id, language)
);

create index if not exists audio_tts_jobs_status_idx on public.audio_tts_jobs (status);

alter table public.audio_tts_jobs enable row level security;

drop policy if exists "Admins manage audio tts jobs" on public.audio_tts_jobs;
create policy "Admins manage audio tts jobs"
  on public.audio_tts_jobs for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select, insert, update, delete on public.audio_tts_jobs to authenticated;
