-- ============================================
-- FUNCTION: check_email_exists
-- ============================================
-- Checks if an email exists in the profiles table.
-- Returns TRUE if email exists, FALSE otherwise.
--
-- SECURITY DEFINER:
-- This function runs with the privileges of the creator (postgres/superuser),
-- bypassing Row Level Security (RLS). This allows unauthenticated users
-- (who are trying to log in) to check if an email is registered.
--
-- SECURITY WARNING:
-- Enabling this allows email enumeration. Ensure this trade-off is acceptable.

CREATE OR REPLACE FUNCTION check_email_exists(email_check TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER -- Essential to bypass RLS for unauthenticated users
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM profiles
    WHERE LOWER(email) = LOWER(email_check) -- Case-insensitive check
  );
END;
$$;

COMMENT ON FUNCTION check_email_exists IS 'Checks if an email is registered (bypassing RLS). Used for specific login error messages.';
