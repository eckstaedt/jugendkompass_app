
DROP POLICY IF EXISTS "Only admins can create polls" ON public.polls;
DROP POLICY IF EXISTS "Only admins can update polls" ON public.polls;
DROP POLICY IF EXISTS "Only admins can delete polls" ON public.polls;
DROP POLICY IF EXISTS "Only admins can create poll options" ON public.poll_options;
DROP POLICY IF EXISTS "Only admins can update poll options" ON public.poll_options;
DROP POLICY IF EXISTS "Only admins can delete poll options" ON public.poll_options;

CREATE POLICY "Only admins can create polls" ON public.polls FOR INSERT TO authenticated WITH CHECK (public.is_admin(auth.uid()));
CREATE POLICY "Only admins can update polls" ON public.polls FOR UPDATE TO authenticated USING (public.is_admin(auth.uid()));
CREATE POLICY "Only admins can delete polls" ON public.polls FOR DELETE TO authenticated USING (public.is_admin(auth.uid()));

CREATE POLICY "Only admins can create poll options" ON public.poll_options FOR INSERT TO authenticated WITH CHECK (public.is_admin(auth.uid()));
CREATE POLICY "Only admins can update poll options" ON public.poll_options FOR UPDATE TO authenticated USING (public.is_admin(auth.uid()));
CREATE POLICY "Only admins can delete poll options" ON public.poll_options FOR DELETE TO authenticated USING (public.is_admin(auth.uid()));
