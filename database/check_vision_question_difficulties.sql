-- Check the actual questions for Orientation - Vision
SELECT 
  q.id,
  q.title,
  q.description,
  q.difficulty,
  q.level_id,
  dl.title as current_level
FROM questions q
JOIN departments d ON q.dept_id = d.id
LEFT JOIN dept_levels dl ON q.level_id = dl.id
WHERE d.title = 'Orientation - Vision'
ORDER BY q.difficulty;

-- If you want to manually assign specific questions to Easy and Mid levels:
-- First, get the level IDs
SELECT 
  id as level_id,
  level_number,
  title as level_name
FROM dept_levels
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
ORDER BY level_number;
