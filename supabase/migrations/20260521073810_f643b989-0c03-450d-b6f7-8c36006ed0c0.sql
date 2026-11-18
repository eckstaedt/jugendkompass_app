CREATE TABLE public.test_push_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  label text NOT NULL,
  fcm_token text NOT NULL,
  platform text,
  language text NOT NULL DEFAULT 'de',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.test_push_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can select test push devices"
  ON public.test_push_devices FOR SELECT
  USING (public.is_admin(auth.uid()));

CREATE POLICY "Admins can insert test push devices"
  ON public.test_push_devices FOR INSERT
  WITH CHECK (public.is_admin(auth.uid()));

CREATE POLICY "Admins can update test push devices"
  ON public.test_push_devices FOR UPDATE
  USING (public.is_admin(auth.uid()));

CREATE POLICY "Admins can delete test push devices"
  ON public.test_push_devices FOR DELETE
  USING (public.is_admin(auth.uid()));