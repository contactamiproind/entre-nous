-- ============================================
-- Cleanup Script: Remove Redundant Tables/Views
-- ============================================
-- Purpose: Drop usr_stat table and user_progress_summary view
-- These are now replaced by usr_progress and usr_dept tables
-- ============================================

-- IMPORTANT: Run this AFTER verifying the new schema works correctly
-- and AFTER updating all Flutter code references

-- ============================================
-- ANALYSIS SUMMARY
-- ============================================

/*
OLD SCHEMA:
-----------
1. usr_stat - Tracked individual question answers
   - Columns: user_id, department_id, question_id, user_answer, is_correct, points_earned
   - Also had: orientation_completed flag
   
2. user_progress_summary - View for aggregated progress
   - Aggregated data from usr_stat
   - Used for dashboard statistics

NEW SCHEMA (Replacement):
------------------------
1. usr_progress - Tracks individual question assignments AND answers
   - All functionality of usr_stat PLUS:
   - Question assignment tracking (status: pending/answered/skipped)
   - Attempt count, time tracking
   - Denormalized question metadata for performance
   
2. usr_dept - Department assignment with auto-aggregated summary
   - Replaces user_progress_summary functionality
   - Auto-updated via trigger when usr_progress changes
   - Includes: total_questions, answered_questions, progress_percentage, etc.

CONCLUSION:
-----------
✅ usr_stat is FULLY REPLACED by usr_progress
✅ user_progress_summary is FULLY REPLACED by usr_dept (with trigger)
✅ Safe to drop both after code migration
*/

-- ============================================
-- CODE REFERENCES TO UPDATE BEFORE DROPPING
-- ============================================

/*
Files that reference usr_stat (need updating):
1. lib/services/department_service.dart - orientation_completed checks
2. lib/services/pathway_service.dart - orientation tracking
3. lib/services/progress_service.dart - saveQuestionAnswer, getQuizAnswers, hasAnsweredQuestion
4. lib/services/user_service.dart - deleteUser cleanup
5. lib/screens/user_management_screen.dart - user deletion

Files that reference user_progress_summary (need updating):
1. lib/services/pathway_service.dart - isOrientationCompleted
2. lib/services/progress_service.dart - getUserProgressSummary, getUserStats, getAllUserProgress

MIGRATION STRATEGY:
------------------
1. Update progress_service.dart to use usr_progress instead of usr_stat
2. Update orientation checks to query usr_dept instead of usr_stat
3. Update summary queries to use usr_dept instead of user_progress_summary
4. Test thoroughly
5. Run this cleanup script
*/

-- ============================================
-- STEP 1: Backup existing data (OPTIONAL)
-- ============================================

-- Uncomment if you want to backup data before dropping
/*
CREATE TABLE IF NOT EXISTS usr_stat_backup AS 
SELECT * FROM usr_stat;

CREATE TABLE IF NOT EXISTS user_progress_summary_backup AS 
SELECT * FROM user_progress_summary;
*/

-- ============================================
-- STEP 2: Drop dependent objects first
-- ============================================

-- Drop any views that depend on usr_stat
DROP VIEW IF EXISTS user_progress_summary CASCADE;

-- Drop any triggers on usr_stat
DROP TRIGGER IF EXISTS update_usr_stat_timestamp ON usr_stat;

-- Drop any functions that reference usr_stat
-- (Add any custom functions here if they exist)

-- ============================================
-- STEP 3: Drop the redundant table
-- ============================================

DROP TABLE IF EXISTS usr_stat CASCADE;

-- ============================================
-- STEP 4: Verify new schema is working
-- ============================================

-- Check that usr_progress exists and has data
DO $$
DECLARE
    progress_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO progress_count FROM usr_progress;
    RAISE NOTICE 'usr_progress table has % records', progress_count;
    
    IF progress_count = 0 THEN
        RAISE WARNING 'usr_progress table is empty! Make sure to assign pathways to users.';
    END IF;
END $$;

-- Check that usr_dept exists and has data
DO $$
DECLARE
    dept_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO dept_count FROM usr_dept;
    RAISE NOTICE 'usr_dept table has % records', dept_count;
    
    IF dept_count = 0 THEN
        RAISE WARNING 'usr_dept table is empty! Make sure to assign pathways to users.';
    END IF;
END $$;

-- ============================================
-- STEP 5: Create compatibility views (OPTIONAL)
-- ============================================

-- If you want to maintain backward compatibility temporarily,
-- create views with old names that map to new tables

-- View to replace user_progress_summary
CREATE OR REPLACE VIEW user_progress_summary AS
SELECT 
    user_id,
    dept_id as department_id,
    answered_questions as total_questions_answered,
    correct_answers,
    total_score,
    progress_percentage,
    completed_levels,
    total_levels,
    last_activity_at as last_activity
FROM usr_dept
WHERE status = 'active';

COMMENT ON VIEW user_progress_summary IS 'Compatibility view - maps to usr_dept table';

-- ============================================
-- STEP 6: Update orientation_completed tracking
-- ============================================

-- Since usr_stat had orientation_completed flag,
-- we need to ensure this is tracked in profiles table

-- Check if profiles.orientation_completed exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'orientation_completed'
    ) THEN
        ALTER TABLE profiles ADD COLUMN orientation_completed BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added orientation_completed column to profiles table';
    END IF;
END $$;

-- Create function to check orientation completion based on usr_dept
CREATE OR REPLACE FUNCTION is_orientation_completed(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_orientation_dept_id UUID;
    v_progress_pct NUMERIC;
BEGIN
    -- Get orientation department ID
    SELECT id INTO v_orientation_dept_id
    FROM departments
    WHERE category = 'Orientation'
    LIMIT 1;
    
    IF v_orientation_dept_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if user has completed orientation (100% progress)
    SELECT progress_percentage INTO v_progress_pct
    FROM usr_dept
    WHERE user_id = p_user_id
    AND dept_id = v_orientation_dept_id
    AND status IN ('active', 'completed');
    
    RETURN COALESCE(v_progress_pct >= 100, FALSE);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION is_orientation_completed IS 'Check if user has completed orientation based on usr_dept progress';

-- ============================================
-- STEP 7: Summary
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Cleanup completed successfully!';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Dropped tables/views:';
    RAISE NOTICE '  - usr_stat (replaced by usr_progress)';
    RAISE NOTICE '  - user_progress_summary (replaced by usr_dept)';
    RAISE NOTICE '';
    RAISE NOTICE 'Created compatibility view:';
    RAISE NOTICE '  - user_progress_summary (maps to usr_dept)';
    RAISE NOTICE '';
    RAISE NOTICE 'Created helper function:';
    RAISE NOTICE '  - is_orientation_completed(user_id)';
    RAISE NOTICE '============================================';
END $$;

-- ============================================
-- End of cleanup script
-- ============================================
