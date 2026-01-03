-- Check Orientation-Vision JSONB vs actual levels

-- Check JSONB content
SELECT 
  'JSONB CONTENT' as info,
  title,
  levels,
  jsonb_array_length(levels) as jsonb_count
FROM departments
WHERE title = 'Orientation - Vision';

-- Check actual dept_levels
SELECT 
  'ACTUAL DEPT_LEVELS' as info,
  dl.id,
  dl.title,
  dl.level_number,
  d.title as department,
  COUNT(q.id) as question_count
FROM dept_levels dl
JOIN departments d ON d.id = dl.dept_id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.title = 'Orientation - Vision'
GROUP BY dl.id, dl.title, dl.level_number, d.title
ORDER BY dl.level_number;

-- Check if app is loading correct department
SELECT 
  'DEPARTMENT ID CHECK' as info,
  id,
  title
FROM departments
WHERE title LIKE '%Vision%'
ORDER BY title;
