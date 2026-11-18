DROP POLICY IF EXISTS "Allow anon access" ON public.device_tokens;

CREATE POLICY "Devices can register"
ON public.device_tokens FOR INSERT TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "Devices can update their settings"
ON public.device_tokens FOR UPDATE TO anon, authenticated
USING (true) WITH CHECK (true);

CREATE POLICY "Admins can read device tokens"
ON public.device_tokens FOR SELECT TO authenticated
USING (public.is_admin(auth.uid()));

CREATE POLICY "Admins can delete device tokens"
ON public.device_tokens FOR DELETE TO authenticated
USING (public.is_admin(auth.uid()));

REVOKE SELECT, DELETE ON public.device_tokens FROM anon;
GRANT INSERT, UPDATE ON public.device_tokens TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.device_tokens TO authenticated;
GRANT ALL ON public.device_tokens TO service_role;