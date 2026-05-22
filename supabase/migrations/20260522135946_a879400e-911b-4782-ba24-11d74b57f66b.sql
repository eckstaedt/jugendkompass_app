
ALTER TABLE public.verse_of_the_day ADD COLUMN IF NOT EXISTS image_url text;

INSERT INTO storage.buckets (id, name, public)
VALUES ('verse-images', 'verse-images', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public read verse-images"
ON storage.objects FOR SELECT
USING (bucket_id = 'verse-images');

CREATE POLICY "Admins can upload verse-images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'verse-images' AND is_admin(auth.uid()));

CREATE POLICY "Admins can update verse-images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'verse-images' AND is_admin(auth.uid()));

CREATE POLICY "Admins can delete verse-images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'verse-images' AND is_admin(auth.uid()));
