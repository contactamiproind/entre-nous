-- ============================================
-- SIMPLER SOLUTION: DISABLE EMAIL CONFIRMATION
-- ============================================
-- The easiest fix is to disable email confirmation in Supabase
-- This allows users to be created immediately without waiting for email confirmation

-- INSTRUCTIONS:
-- 1. Go to Supabase Dashboard
-- 2. Navigate to Authentication > Settings
-- 3. Find "Enable email confirmations"
-- 4. Toggle it OFF
-- 5. Save changes

-- After disabling email confirmation, the user creation will work because:
-- - User is immediately added to auth.users table
-- - No foreign key constraint violation
-- - Profile can be created right away

-- Alternative: Use the trigger we created earlier (auto_create_profile_trigger.sql)
-- The trigger should work once email confirmation is disabled

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'TO FIX USER CREATION ERROR:';
  RAISE NOTICE '1. Go to Supabase Dashboard';
  RAISE NOTICE '2. Authentication > Settings';
  RAISE NOTICE '3. Disable "Enable email confirmations"';
  RAISE NOTICE '4. Save and try creating user again';
  RAISE NOTICE '==============================================';
END $$;
