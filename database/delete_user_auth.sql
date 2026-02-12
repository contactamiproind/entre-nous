-- Run this in the Supabase SQL Editor to enable full user deletion from the app.
-- This function deletes a user from auth.users, which prevents them from logging back in.
-- It requires SECURITY DEFINER to access the auth schema.

CREATE OR REPLACE FUNCTION public.delete_user_auth(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delete from auth.users (cascades to auth.identities, auth.sessions, etc.)
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;

-- Grant execute permission to authenticated users (admin check should be done in RLS or app logic)
GRANT EXECUTE ON FUNCTION public.delete_user_auth(uuid) TO authenticated;
