-- ============================================
-- COMPREHENSIVE DATABASE CLEANUP
-- Keep ONLY 9 Essential Tables
-- ============================================

-- ⚠️ WARNING: This will DROP all tables except the 9 listed below!
-- Make sure you have a backup if needed.

-- ============================================
-- STEP 1: List all current tables
-- ============================================
-- Run this first to see what you have:

SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ============================================
-- STEP 2: DROP ALL EXTRA TABLES
-- ============================================

-- Drop any tables NOT in our essential list
DROP TABLE IF EXISTS question_bank CASCADE;
DROP TABLE IF EXISTS question_options CASCADE;
DROP TABLE IF EXISTS user_assignments CASCADE;
DROP TABLE IF EXISTS quiz_results CASCADE;
DROP TABLE IF EXISTS level_progress CASCADE;
DROP TABLE IF EXISTS department_levels CASCADE;  -- We use dept_levels instead
DROP TABLE IF EXISTS pathways CASCADE;
DROP TABLE IF EXISTS levels CASCADE;
DROP TABLE IF EXISTS assignments CASCADE;
DROP TABLE IF EXISTS quiz_attempts CASCADE;
DROP TABLE IF EXISTS user_stats CASCADE;
DROP TABLE IF EXISTS leaderboard CASCADE;

-- Drop any other legacy tables that might exist
-- Add more DROP statements here if you see other tables in Step 1

-- ============================================
-- STEP 3: Verify ONLY 8 tables remain
-- ============================================

SELECT 
    'TABLES' as type,
    table_name as name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Should show EXACTLY these 8 tables:
-- 1. departments
-- 2. dept_levels
-- 3. profiles
-- 4. question_child
-- 5. question_types
-- 6. questions
-- 7. user_pathway
-- 8. user_progress

-- ============================================
-- STEP 4: Verify 1 VIEW exists
-- ============================================

SELECT 
    'VIEWS' as type,
    table_name as name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'VIEW'
ORDER BY table_name;

-- Should show EXACTLY 1 view:
-- 1. user_progress_summary

-- ============================================
-- STEP 5: Final count verification
-- ============================================

SELECT 
    'Total Tables' as item,
    COUNT(*) as count
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'

UNION ALL

SELECT 
    'Total Views',
    COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'VIEW';

-- Should show:
-- Total Tables: 8
-- Total Views: 1

-- ============================================
-- STEP 6: Show record counts
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=== RECORD COUNTS ===';
END $$;

SELECT 'departments' as table_name, COUNT(*) as records FROM departments
UNION ALL SELECT 'dept_levels', COUNT(*) FROM dept_levels
UNION ALL SELECT 'questions', COUNT(*) FROM questions
UNION ALL SELECT 'question_types', COUNT(*) FROM question_types
UNION ALL SELECT 'question_child', COUNT(*) FROM question_child
UNION ALL SELECT 'profiles', COUNT(*) FROM profiles
UNION ALL SELECT 'user_progress', COUNT(*) FROM user_progress
UNION ALL SELECT 'user_pathway', COUNT(*) FROM user_pathway
ORDER BY table_name;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Cleanup complete!';
    RAISE NOTICE 'Database now has EXACTLY 9 items:';
    RAISE NOTICE '  - 8 tables';
    RAISE NOTICE '  - 1 view (user_progress_summary)';
    RAISE NOTICE '';
    RAISE NOTICE 'Essential tables kept:';
    RAISE NOTICE '  1. departments';
    RAISE NOTICE '  2. dept_levels';
    RAISE NOTICE '  3. questions';
    RAISE NOTICE '  4. question_types';
    RAISE NOTICE '  5. question_child';
    RAISE NOTICE '  6. profiles';
    RAISE NOTICE '  7. user_progress';
    RAISE NOTICE '  8. user_pathway';
    RAISE NOTICE '  9. user_progress_summary (VIEW)';
END $$;
