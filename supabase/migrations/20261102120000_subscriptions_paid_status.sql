-- Bezahlt-Status für Print-Abonnements
-- Die frühere Spalte "bezahlt" (nullable) wird zu "paid" (NOT NULL) umbenannt,
-- dazu kommen Zeitpunkt und Admin, der die Zahlung bestätigt hat.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'subscriptions' AND column_name = 'bezahlt'
  ) THEN
    ALTER TABLE public.subscriptions RENAME COLUMN bezahlt TO paid;
  END IF;
END $$;

ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS paid boolean;
UPDATE public.subscriptions SET paid = false WHERE paid IS NULL;
ALTER TABLE public.subscriptions
  ALTER COLUMN paid SET DEFAULT false,
  ALTER COLUMN paid SET NOT NULL;

ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS paid_at timestamptz,
  ADD COLUMN IF NOT EXISTS paid_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;

UPDATE public.subscriptions SET paid_at = COALESCE(paid_at, updated_at) WHERE paid AND paid_at IS NULL;

CREATE INDEX IF NOT EXISTS subscriptions_paid_idx ON public.subscriptions (paid);

-- Pflegt paid_at / paid_by automatisch und verhindert, dass Nicht-Admins
-- (z. B. das öffentliche Bestellformular in der App) den Status setzen.
CREATE OR REPLACE FUNCTION public.handle_subscription_paid()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_privileged boolean :=
    auth.role() = 'service_role'
    OR (auth.uid() IS NOT NULL AND public.is_admin(auth.uid()));
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NOT v_is_privileged THEN
      NEW.paid := false;
    END IF;
    IF NEW.paid THEN
      NEW.paid_at := COALESCE(NEW.paid_at, now());
      NEW.paid_by := COALESCE(NEW.paid_by, auth.uid());
    ELSE
      NEW.paid_at := NULL;
      NEW.paid_by := NULL;
    END IF;
    RETURN NEW;
  END IF;

  -- UPDATE
  IF NEW.paid IS DISTINCT FROM OLD.paid THEN
    IF NOT v_is_privileged THEN
      RAISE EXCEPTION 'Nur Admins dürfen den Bezahlt-Status ändern'
        USING ERRCODE = '42501';
    END IF;
    IF NEW.paid THEN
      NEW.paid_at := now();
      NEW.paid_by := auth.uid();
    ELSE
      NEW.paid_at := NULL;
      NEW.paid_by := NULL;
    END IF;
  ELSE
    -- Zeitstempel/Admin können nicht unabhängig vom Status manipuliert werden
    NEW.paid_at := OLD.paid_at;
    NEW.paid_by := OLD.paid_by;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS subscriptions_paid_status ON public.subscriptions;
CREATE TRIGGER subscriptions_paid_status
BEFORE INSERT OR UPDATE ON public.subscriptions
FOR EACH ROW EXECUTE FUNCTION public.handle_subscription_paid();
