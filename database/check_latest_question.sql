-- Check what data was actually saved for the newest question
SELECT 
    id,
    title,
    description,
    options,
    correct_answer,
    difficulty,
    points,
    created_at
FROM questions
ORDER BY created_at DESC
LIMIT 1;
