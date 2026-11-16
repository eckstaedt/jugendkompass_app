-- Russian covers too: queue ru for every image with text, new images get en + ru.
insert into public.image_translations (source_url, language, entity_type, entity_id, title, status)
select source_url, 'ru', entity_type, entity_id, title, case when status = 'no_text' then 'no_text' else 'pending' end
from public.image_translations where language = 'en'
on conflict (source_url, language) do nothing;
create or replace function public.enqueue_image_translation(
  p_url text, p_entity_type text, p_entity_id text, p_title text
) returns void language sql security definer set search_path = public as $$
  insert into public.image_translations (source_url, language, entity_type, entity_id, title)
  select p_url, l, p_entity_type, p_entity_id, p_title
  from unnest(array['en', 'ru']) as l
  where p_url is not null and p_url like 'http%'
  on conflict (source_url, language) do nothing;
$$;
