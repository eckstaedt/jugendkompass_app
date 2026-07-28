-- 1) Bestehende Duplikate entfernen: pro fcm_token nur der neueste Eintrag bleibt
DELETE FROM public.device_tokens dt
USING public.device_tokens keep
WHERE dt.fcm_token IS NOT NULL
  AND keep.fcm_token = dt.fcm_token
  AND (keep.created_at, keep.id) > (dt.created_at, dt.id);

-- 2) Zukünftige Duplikate verhindern (ohne App-Registrierung zu brechen)
CREATE OR REPLACE FUNCTION public.dedupe_device_tokens()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.fcm_token IS NOT NULL THEN
    DELETE FROM public.device_tokens
    WHERE fcm_token = NEW.fcm_token
      AND id <> NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS device_tokens_dedupe ON public.device_tokens;
CREATE TRIGGER device_tokens_dedupe
AFTER INSERT OR UPDATE OF fcm_token ON public.device_tokens
FOR EACH ROW EXECUTE FUNCTION public.dedupe_device_tokens();