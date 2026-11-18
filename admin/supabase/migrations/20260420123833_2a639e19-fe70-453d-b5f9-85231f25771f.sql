UPDATE public.posts
SET body = '<' || body
WHERE body ~ '^[a-zA-Z][a-zA-Z0-9]*(\s[^<]*)?>';

UPDATE public.impulses
SET impulse_text = '<' || impulse_text
WHERE impulse_text ~ '^[a-zA-Z][a-zA-Z0-9]*(\s[^<]*)?>';