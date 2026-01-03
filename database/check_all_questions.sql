-- Check ALL questions in the database
SELECT id, title, level_id, category, subcategory, created_at
FROM questions
ORDER BY created_at DESC
LIMIT 20;
