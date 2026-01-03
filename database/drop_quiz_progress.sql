-- ============================================
-- DROP quiz_progress TABLE
-- ============================================

-- This table is not needed in the current schema
-- We use user_progress instead for tracking quiz answers

-- Check if table exists first
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'quiz_progress';

-- Drop the table
DROP TABLE IF EXISTS quiz_progress CASCADE;

-- Verify it's gone
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ quiz_progress table dropped successfully';
    RAISE NOTICE 'Current schema now has 8 tables + 1 view';
END $$;
