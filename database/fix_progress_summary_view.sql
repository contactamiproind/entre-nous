-- Fix user_progress_summary view
-- The view was referencing 'dept_id' but the column is actually 'department_id'

DROP VIEW IF EXISTS user_progress_summary;

CREATE VIEW user_progress_summary AS
SELECT 
    user_id,
    department_id,  -- Changed from dept_id to department_id
    COUNT(*) AS total_questions_answered,
    SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) AS correct_answers,
    SUM(points_earned) AS total_score,
    ROUND((SUM(CASE WHEN is_correct THEN 1 ELSE 0 END)::NUMERIC / COUNT(*)) * 100, 2) AS accuracy_percentage,
    MIN(created_at) AS first_activity,
    MAX(created_at) AS last_activity
FROM usr_stat
GROUP BY user_id, department_id;

-- Grant permissions
GRANT SELECT ON user_progress_summary TO authenticated;
