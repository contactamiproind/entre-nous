-- Find the Values question by description (most reliable)

SELECT 
  id,
  title,
  description,
  level_id,
  dept_id
FROM questions
WHERE description = 'Choose the most value-aligned action:'
LIMIT 1;
