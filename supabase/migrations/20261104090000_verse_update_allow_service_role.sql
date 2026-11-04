-- Let the service role (verse image generator, scheduler) update verse rows.
-- Before, only admin *users* passed this trigger, so the generator could not
-- set image_url and every auto-planned verse kept the plain fallback card.
CREATE OR REPLACE FUNCTION public.restrict_verse_update_to_usage_count()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF auth.role() = 'service_role' THEN RETURN NEW; END IF;
  IF public.is_admin(auth.uid()) THEN RETURN NEW; END IF;
  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.content_id IS DISTINCT FROM OLD.content_id
     OR NEW.verse IS DISTINCT FROM OLD.verse
     OR NEW.reference IS DISTINCT FROM OLD.reference
     OR NEW.date IS DISTINCT FROM OLD.date
     OR NEW.image_url IS DISTINCT FROM OLD.image_url
     OR NEW.created_at IS DISTINCT FROM OLD.created_at
  THEN
    RAISE EXCEPTION 'Only admins may modify verse fields other than usage_count';
  END IF;
  RETURN NEW;
END;
$function$;
