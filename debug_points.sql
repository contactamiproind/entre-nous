-- Check usr_progress for the user (assuming we can find them by email or just list recent)
-- We'll list recent usr_progress items to see if there are multiple entries for Orientation
SELECT 
    up.id,
    up.category,
    up.question_text,
    up.score_earned,
    up.question_id,
    q.description
FROM usr_progress up
LEFT JOIN questions q ON up.question_id = q.id
ORDER BY up.created_at DESC
LIMIT 20;

-- Also check how many items total for 'Orientation'
SELECT category, COUNT(*), SUM(score_earned)
FROM usr_progress
GROUP BY category;
