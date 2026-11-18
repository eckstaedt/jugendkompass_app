-- Fix the handle_new_user_role function that's causing signup failures
-- Roles are already stored in the users.role column, so this function should be a no-op
CREATE OR REPLACE FUNCTION public.handle_new_user_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Roles are stored directly in users.role column
    -- This function is kept for backward compatibility with existing triggers
    RETURN NEW;
END;
$$;