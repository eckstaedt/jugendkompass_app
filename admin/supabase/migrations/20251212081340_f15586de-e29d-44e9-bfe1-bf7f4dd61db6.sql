-- Fix poll_votes exposure: restrict SELECT to user's own votes only
DROP POLICY IF EXISTS "Everyone can view total votes" ON poll_votes;

CREATE POLICY "Users can view own votes" 
ON poll_votes 
FOR SELECT 
USING (auth.uid() = user_id);