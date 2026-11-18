
-- Add created_at to tables that are missing it
ALTER TABLE public.audios ADD COLUMN created_at timestamp with time zone NOT NULL DEFAULT now();
ALTER TABLE public.categories ADD COLUMN created_at timestamp with time zone NOT NULL DEFAULT now();
ALTER TABLE public.impulses ADD COLUMN created_at timestamp with time zone NOT NULL DEFAULT now();
ALTER TABLE public.poll_options ADD COLUMN created_at timestamp with time zone NOT NULL DEFAULT now();
ALTER TABLE public.posts ADD COLUMN created_at timestamp with time zone NOT NULL DEFAULT now();
