-- Verify the question was added successfully
SELECT 
    id,
    title,
    difficulty,
    points,
    dept_id,
    created_at
FROM questions
ORDER BY created_at DESC
LIMIT 5;
