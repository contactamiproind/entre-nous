-- Check all questions and their department/level assignments
SELECT 
  q.id,
  q.title,
  d.title as department,
  q.dept_id,
  q.level_id,
  dl.title as level_title,
  dl.level_number
FROM questions q
LEFT JOIN departments d ON q.dept_id = d.id
LEFT JOIN dept_levels dl ON q.level_id = dl.id
ORDER BY d.title, dl.level_number;

-- Check if questions have dept_id but no level_id
SELECT 
  COUNT(*) as total_questions,
  COUNT(dept_id) as with_dept_id,
  COUNT(level_id) as with_level_id,
  COUNT(*) - COUNT(level_id) as missing_level_id
FROM questions;
