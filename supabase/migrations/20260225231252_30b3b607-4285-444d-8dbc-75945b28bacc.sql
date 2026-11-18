
-- Create messages table
CREATE TABLE public.messages (
  id SERIAL PRIMARY KEY,
  content_id uuid REFERENCES public.content(id) ON DELETE CASCADE,
  created_by uuid,
  created_at timestamptz DEFAULT now(),
  message text NOT NULL,
  image_url text
);

-- Enable RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- RLS policies for messages
CREATE POLICY "Anyone can view messages" ON public.messages FOR SELECT USING (true);
CREATE POLICY "Admins can manage messages" ON public.messages FOR ALL USING (public.is_admin(auth.uid()));

-- Trigger for auto content_id
CREATE OR REPLACE TRIGGER messages_content_trigger
  BEFORE INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_message_content();

-- Create videos table
CREATE TABLE public.videos (
  id SERIAL PRIMARY KEY,
  content_id uuid NOT NULL REFERENCES public.content(id) ON DELETE CASCADE,
  title text NOT NULL,
  url text NOT NULL,
  user_id uuid,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;

-- RLS policies for videos
CREATE POLICY "Anyone can view videos" ON public.videos FOR SELECT USING (true);
CREATE POLICY "Admins can manage videos" ON public.videos FOR ALL USING (public.is_admin(auth.uid()));

-- Trigger for auto content_id
CREATE OR REPLACE TRIGGER videos_content_trigger
  BEFORE INSERT ON public.videos
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_video_content();

-- Create content_feed view
CREATE OR REPLACE VIEW public.content_feed AS
SELECT
  c.id AS content_id,
  c.content_type,
  c.created_at,
  COALESCE(p.title, v.title, i.impulse_text, pl.question, m.message, vd.verse) AS title,
  COALESCE(p.body, i.impulse_text, m.message, vd.reference) AS description,
  COALESCE(p.image_url, i.image_url, m.image_url) AS image_url,
  COALESCE(p.id::text, v.id::text, i.id::text, pl.id::text, m.id::text, vd.id::text) AS entity_id,
  NULL::integer AS sort_order,
  COALESCE(i.date, vd.date)::text AS specific_date
FROM public.content c
LEFT JOIN public.posts p ON p.content_id = c.id
LEFT JOIN public.videos v ON v.content_id = c.id
LEFT JOIN public.impulses i ON i.content_id = c.id
LEFT JOIN public.polls pl ON pl.content_id = c.id
LEFT JOIN public.messages m ON m.content_id = c.id
LEFT JOIN public.verse_of_the_day vd ON vd.content_id = c.id
WHERE c.status = 'published';
