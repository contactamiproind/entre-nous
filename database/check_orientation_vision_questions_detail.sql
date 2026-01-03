-- Check ALL questions for Orientation - Vision with their actual difficulty values
SELECT 
  q.id,
  q.title,
  q.description,
  q.difficulty,
  q.level_id,
  dl.title as assigned_level,
  dl.level_number,
  d.title as department
FROM questions q
JOIN departments d ON q.dept_id = d.id
LEFT JOIN dept_levels dl ON q.level_id = dl.id
WHERE d.title = 'Orientation - Vision'
ORDER BY q.difficulty, q.id;

-- Check if there are questions with NULL or unexpected difficulty values
SELECT 
  difficulty,
  COUNT(*) as question_count
FROM questions q
JOIN departments d ON q.dept_id = d.id
WHERE d.title = 'Orientation - Vision'
GROUP BY difficulty;

-- Show the dept_levels for Orientation - Vision
SELECT 
  id as level_id,
  level_number,
  title as level_title,
  category
FROM dept_levels
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
ORDER BY level_number;
