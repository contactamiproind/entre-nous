-- Check what departments exist and their questions
SELECT 
  d.id,
  d.title as department,
  COUNT(DISTINCT dl.id) as level_count,
  COUNT(q.id) as question_count,
  STRING_AGG(DISTINCT q.title, ', ') as questions
FROM departments d
LEFT JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON q.level_id = dl.id
GROUP BY d.id, d.title
ORDER BY d.title;
