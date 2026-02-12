-- Check if the user has multiple entries for the same question_id
-- This would cause the total score to be inflated if we verify simply summing all rows.

SELECT 
    question_id,
    question_text,
    COUNT(*) as attempt_count,
    SUM(score_earned) as total_points_for_question
FROM usr_progress
GROUP BY question_id, question_text
HAVING COUNT(*) > 1;

-- Also show the total score simple sum vs unique sum
SELECT 
    SUM(score_earned) as simple_sum,
    (SELECT SUM(max_score) FROM (
        SELECT MAX(score_earned) as max_score 
        FROM usr_progress 
        GROUP BY question_id
    ) as unique_scores) as correct_unique_sum
FROM usr_progress;
