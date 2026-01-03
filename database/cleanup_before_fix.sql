-- ============================================
-- COMPLETE FIX: Clean Database for Supabase Auth
-- ============================================
-- Run this FIRST to clean everything

-- Step 1: Drop all old data (we'll recreate fresh)
TRUNCATE TABLE user_progress CASCADE;
TRUNCATE TABLE user_assignments CASCADE;
TRUNCATE TABLE quiz_progress CASCADE;
TRUNCATE TABLE profiles CASCADE;

-- Step 2: Drop the old users table (we're using auth.users now)
DROP TABLE IF EXISTS users CASCADE;

-- Step 3: Now run the fix_supabase_auth.sql script
-- (The one you just tried to run)

-- ============================================
-- After running this, run fix_supabase_auth.sql
-- ============================================
