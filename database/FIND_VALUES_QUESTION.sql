-- Find the actual "Single Tap Choice" Values question

SELECT 
  'FIND VALUES QUESTION' as info,
  id,
  title,
  description,
  level_id,
  dept_id,
  difficulty
FROM questions
WHERE title LIKE '%Single Tap%'
   OR description LIKE '%value-aligned%'
ORDER BY title;
