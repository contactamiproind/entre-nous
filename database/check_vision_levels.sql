-- Check Vision pathway levels in dept_levels table
SELECT 
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  dl.category,
  COUNT(q.id) as question_count
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON dl.id = q.level_id
WHERE d.title LIKE '%Vision%'
GROUP BY d.title, dl.level_number, dl.title, dl.category
ORDER BY dl.level_number;

-- Also check if there are multiple Vision-related departments
SELECT 
  id,
  title,
  description
FROM departments
WHERE title LIKE '%Vision%'
ORDER BY title;
