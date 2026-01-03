-- Find the "Single Tap Choice" question in the entire questions table
SELECT 
  q.id,
  q.title,
  q.description,
  q.difficulty,
  d.title as department,
  q.dept_id,
  q.level_id
FROM questions q
LEFT JOIN departments d ON q.dept_id = d.id
WHERE q.title LIKE '%Single%' OR q.description LIKE '%Ease for a client%'
ORDER BY q.title;

-- Also check if there are any questions with NULL dept_id
SELECT 
  id,
  title,
  description,
  difficulty,
  dept_id,
  level_id
FROM questions
WHERE dept_id IS NULL OR title LIKE '%Single%';
