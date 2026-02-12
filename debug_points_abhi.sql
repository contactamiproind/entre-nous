-- Check points for user Abhi
SELECT 
    up.id,
    up.question_id,
    q.title,
    up.is_correct,
    up.score_earned,
    up.status,
    up.created_at
FROM usr_progress up
JOIN questions q ON up.question_id = q.id
JOIN profiles p ON up.user_id = p.user_id
WHERE p.full_name = 'Abhi'
ORDER BY up.created_at DESC
LIMIT 20;

-- Check total score calculation
SELECT 
    p.full_name,
    COUNT(DISTINCT up.question_id) as unique_questions,
    SUM(up.score_earned) as total_score_sum,
    COUNT(*) as total_records
FROM usr_progress up
JOIN profiles p ON up.user_id = p.user_id
WHERE p.full_name = 'Abhi'
GROUP BY p.full_name;

-- Check best scores per question (matching dashboard logic)
WITH best_scores AS (
    SELECT 
        up.question_id,
        MAX(up.score_earned) as best_score
    FROM usr_progress up
    JOIN profiles p ON up.user_id = p.user_id
    WHERE p.full_name = 'Abhi'
    GROUP BY up.question_id
)
SELECT 
    COUNT(*) as unique_questions,
    SUM(best_score) as total_points
FROM best_scores;
