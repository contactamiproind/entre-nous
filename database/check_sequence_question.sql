-- Check the sequence builder question data
SELECT id, title, description, options, quest_type_id
FROM questions
WHERE title LIKE '%Sequence%' OR title LIKE '%sequence%'
ORDER BY created_at DESC
LIMIT 5;
