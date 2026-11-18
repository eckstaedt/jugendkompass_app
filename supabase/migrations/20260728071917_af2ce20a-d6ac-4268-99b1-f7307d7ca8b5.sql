DROP POLICY IF EXISTS "Public can upload images to posts bucket" ON storage.objects;
DROP POLICY IF EXISTS "Public can update images in posts bucket" ON storage.objects;
DROP POLICY IF EXISTS "Public can delete images from posts bucket" ON storage.objects;

CREATE POLICY "Admins can upload to posts bucket"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'posts' AND public.is_admin(auth.uid()));

CREATE POLICY "Admins can update posts bucket"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'posts' AND public.is_admin(auth.uid()))
WITH CHECK (bucket_id = 'posts' AND public.is_admin(auth.uid()));

CREATE POLICY "Admins can delete from posts bucket"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'posts' AND public.is_admin(auth.uid()));