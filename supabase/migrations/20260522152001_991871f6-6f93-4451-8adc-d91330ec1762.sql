UPDATE public.poll_options o
SET votes = COALESCE(sub.cnt, 0)
FROM (
  SELECT option_id, COUNT(*)::int AS cnt
  FROM public.poll_votes
  GROUP BY option_id
) sub
WHERE sub.option_id = o.id;

UPDATE public.poll_options
SET votes = 0
WHERE id NOT IN (SELECT DISTINCT option_id FROM public.poll_votes);
