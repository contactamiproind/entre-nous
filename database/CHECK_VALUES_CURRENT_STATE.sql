-- Simple check: what is the question's current level_id?

SELECT 
  id,
  title,
  level_id,
  dept_id
FROM questions
WHERE title = 'Single Tap Choice'
  AND description LIKE '%value-aligned%'
LIMIT 1;
