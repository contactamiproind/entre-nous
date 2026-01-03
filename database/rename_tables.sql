-- Database Table Rename Migration Script
-- Run this in Supabase SQL Editor AFTER updating the Dart code

-- IMPORTANT: This script renames tables to match the updated code
-- Tables to rename:
--   question_child → quest_det
--   user_progress → usr_stat  
--   question_types → quest_types

-- Step 1: Rename tables
ALTER TABLE IF EXISTS question_child RENAME TO quest_det;
ALTER TABLE IF EXISTS user_progress RENAME TO usr_stat;
ALTER TABLE IF EXISTS question_types RENAME TO quest_types;

-- Step 2: Update user_progress_summary view to reference new table name
DROP VIEW IF EXISTS user_progress_summary;

CREATE VIEW user_progress_summary AS
SELECT 
    user_id,
    department_id,
    COUNT(*) AS total_questions_answered,
    SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) AS correct_answers,
    SUM(points_earned) AS total_score,
    ROUND((SUM(CASE WHEN is_correct THEN 1 ELSE 0 END)::NUMERIC / COUNT(*)) * 100, 2) AS accuracy_percentage,
    MIN(created_at) AS first_activity,
    MAX(created_at) AS last_activity
FROM usr_stat
GROUP BY user_id, department_id;

-- Step 3: Grant permissions on renamed tables (if needed)
GRANT ALL ON quest_det TO authenticated;
GRANT ALL ON usr_stat TO authenticated;
GRANT ALL ON quest_types TO authenticated;
GRANT SELECT ON user_progress_summary TO authenticated;

-- Step 4: Update RLS policies (if they reference table names in policy definitions)
-- Note: RLS policies are automatically moved with the table rename
-- But if any policies have table names in their expressions, update them here

-- Verification queries
-- Run these to verify the rename was successful:
-- SELECT COUNT(*) FROM quest_det;
-- SELECT COUNT(*) FROM usr_stat;
-- SELECT COUNT(*) FROM quest_types;
-- SELECT * FROM user_progress_summary LIMIT 1;
