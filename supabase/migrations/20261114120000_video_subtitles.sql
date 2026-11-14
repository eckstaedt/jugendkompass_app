-- English subtitles for videos (tool/subtitles, Whisper). Keyed by video URL.
create table if not exists public.video_subtitles (
  video_url text not null,
  language text not null,
  url text not null,
  created_at timestamptz not null default now(),
  primary key (video_url, language)
);
alter table public.video_subtitles enable row level security;
drop policy if exists "subtitles readable" on public.video_subtitles;
create policy "subtitles readable" on public.video_subtitles for select using (true);
