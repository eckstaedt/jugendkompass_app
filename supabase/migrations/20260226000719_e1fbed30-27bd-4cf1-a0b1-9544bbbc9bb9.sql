
ALTER TABLE public.editions
  ADD COLUMN title text,
  ADD COLUMN body text,
  ADD COLUMN image_url text,
  ADD COLUMN pdf_url text;
