-- Check if question details exist in quest_det table
SELECT 
    qd.*,
    q.title as question_title
FROM quest_det qd
JOIN questions q ON qd.question_id = q.id
ORDER BY qd.created_at DESC
LIMIT 5;

-- Also check questions without details
SELECT 
    q.id,
    q.title,
    q.difficulty,
    q.points
FROM questions q
LEFT JOIN quest_det qd ON q.id = qd.question_id
WHERE qd.question_id IS NULL;
