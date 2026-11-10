-- Plain nature photo (without text) behind the "Vers des Tages" share image.
-- Filled by tool/verse_images/generate.mjs; used by the home-screen widgets.
-- NULL for manually uploaded share images (their background is unknown).
alter table public.verse_of_the_day
  add column if not exists background_image_url text;
