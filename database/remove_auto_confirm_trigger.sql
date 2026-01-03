-- Remove the problematic auto-confirm trigger
DROP TRIGGER IF EXISTS on_auth_user_created_auto_confirm ON auth.users;
DROP FUNCTION IF EXISTS auto_confirm_user();

-- This removes the trigger that was causing the "Database error saving new user" error
