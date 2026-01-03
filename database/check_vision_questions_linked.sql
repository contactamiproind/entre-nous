-- Check if questions are linked to Vision dept_levels
SELECT 
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  q.id as question_id,
  q.title as question_title,
  q.level_id
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON dl.id = q.level_id
WHERE d.title = 'Vision'
ORDER BY dl.level_number, q.id;

-- Check if Vision questions exist but aren't linked
SELECT 
  q.id,
  q.title,
  q.dept_id,
  q.level_id,
  d.title as department
FROM questions q
JOIN departments d ON q.dept_id = d.id
WHERE d.title = 'Vision';
