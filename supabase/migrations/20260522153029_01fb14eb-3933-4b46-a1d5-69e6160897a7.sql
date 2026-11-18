ALTER TABLE public.poll_options ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;

CREATE INDEX idx_poll_options_sort_order ON public.poll_options (poll_id, sort_order);