-- Only English cover images are translated (cost). Other languages keep the
-- original image. Remove their queue entries and queue only 'en' from now on.
delete from public.image_translations where language <> 'en' and status in ('pending', 'no_text', 'failed');

create or replace function public.enqueue_image_translation(
  p_url text, p_entity_type text, p_entity_id text, p_title text
) returns void language sql security definer set search_path = public as $$
  insert into public.image_translations (source_url, language, entity_type, entity_id, title)
  select p_url, l, p_entity_type, p_entity_id, p_title
  from unnest(array['en']) as l
  where p_url is not null and p_url like 'http%'
  on conflict (source_url, language) do nothing;
$$;
