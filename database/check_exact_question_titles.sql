-- Check exact question titles for Orientation - Vision
SELECT 
  id,
  title,
  description,
  difficulty,
  dept_id,
  level_id
FROM questions
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
ORDER BY title;
