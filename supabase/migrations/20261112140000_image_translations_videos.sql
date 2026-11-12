-- Video thumbnails get an English version too (same pipeline as covers).
drop trigger if exists queue_image_translation on public.videos;
create trigger queue_image_translation after insert or update of image_url on public.videos
  for each row execute function public.queue_image_translation_trigger();
select count(public.enqueue_image_translation(image_url, 'videos', id::text, title)) from public.videos;
