-- Quick verification: Show question distribution

SELECT 
  d.title as department,
  dl.title as level,
  COUNT(q.id) as question_count
FROM departments d
JOIN dept_levels dl ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.title IN ('Vision', 'Orientation', 'Orientation - Values')
GROUP BY d.id, d.title, dl.id, dl.title, dl.level_number
ORDER BY d.title, dl.level_number;
