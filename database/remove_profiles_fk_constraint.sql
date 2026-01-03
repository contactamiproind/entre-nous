-- ============================================
-- SIMPLE FIX: Allow profile creation without auth user
-- ============================================
-- Remove the foreign key constraint temporarily to allow profile creation
-- This is a workaround for the email confirmation issue

-- First, let's check the current constraint
SELECT conname, conrelid::regclass, confrelid::regclass
FROM pg_constraint
WHERE conname LIKE '%profiles%user%';

-- Drop the foreign key constraint on profiles.user_id
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_user_id_fkey;

-- Now profiles can be created without requiring the user to exist in auth.users
-- This allows admin to create user profiles that can be linked later

-- Add a note column to track manually created users
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS manually_created BOOLEAN DEFAULT false;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Foreign key constraint removed!';
  RAISE NOTICE 'Profiles can now be created independently.';
  RAISE NOTICE 'Users can sign up later and link to their profile.';
  RAISE NOTICE '==============================================';
END $$;
