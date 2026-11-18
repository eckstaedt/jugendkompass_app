
-- 1. Reset votes data
DELETE FROM public.poll_votes;
UPDATE public.poll_options SET votes = 0;

-- 2. Enforce one vote per (poll, user) and require user_id
ALTER TABLE public.poll_votes ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.poll_votes ALTER COLUMN poll_id SET NOT NULL;
ALTER TABLE public.poll_votes ALTER COLUMN option_id SET NOT NULL;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'poll_votes_poll_user_unique'
  ) THEN
    ALTER TABLE public.poll_votes
      ADD CONSTRAINT poll_votes_poll_user_unique UNIQUE (poll_id, user_id);
  END IF;
END $$;

-- 3. RLS policies (refresh)
DROP POLICY IF EXISTS "Users can update their own votes" ON public.poll_votes;
DROP POLICY IF EXISTS "Users can view own votes" ON public.poll_votes;
DROP POLICY IF EXISTS "Users can vote on polls" ON public.poll_votes;

CREATE POLICY "Users can view own votes"
ON public.poll_votes FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can vote on polls"
ON public.poll_votes FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own votes"
ON public.poll_votes FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 4. Trigger-based vote counting
CREATE OR REPLACE FUNCTION public.sync_poll_option_votes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.poll_options SET votes = COALESCE(votes, 0) + 1 WHERE id = NEW.option_id;
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.option_id IS DISTINCT FROM OLD.option_id THEN
      UPDATE public.poll_options SET votes = GREATEST(COALESCE(votes, 0) - 1, 0) WHERE id = OLD.option_id;
      UPDATE public.poll_options SET votes = COALESCE(votes, 0) + 1 WHERE id = NEW.option_id;
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.poll_options SET votes = GREATEST(COALESCE(votes, 0) - 1, 0) WHERE id = OLD.option_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS poll_votes_sync_counts ON public.poll_votes;
CREATE TRIGGER poll_votes_sync_counts
AFTER INSERT OR UPDATE OR DELETE ON public.poll_votes
FOR EACH ROW EXECUTE FUNCTION public.sync_poll_option_votes();
