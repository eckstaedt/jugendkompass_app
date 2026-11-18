DROP POLICY IF EXISTS "Only admins can update posts" ON public.posts;

CREATE POLICY "Only admins can update posts"
ON public.posts FOR UPDATE
TO authenticated
USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));