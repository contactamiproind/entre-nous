-- Check the distribution of scores to ensure no 100s/50s/25s remain for MCQs
-- and to verify that correct answers have points.

SELECT 
    score_earned, 
    COUNT(*) as count,
    MIN(created_at) as earliest_date,
    MAX(created_at) as latest_date
FROM usr_progress
GROUP BY score_earned
ORDER BY score_earned DESC;

-- Also check for any Correct answers that still have 0 points
SELECT COUNT(*) as correct_zero_points_count
FROM usr_progress
WHERE is_correct = true AND score_earned = 0;

-- Show a sample of recent activity
SELECT 
    question_text, 
    is_correct, 
    score_earned, 
    created_at
FROM usr_progress
ORDER BY created_at DESC
LIMIT 10;
