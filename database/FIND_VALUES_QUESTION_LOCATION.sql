-- Find where the Values question is currently located

SELECT 
  'VALUES QUESTION LOCATION' as info,
  q.id,
  q.title,
  q.description,
  q.level_id,
  dl.title as level_name,
  dl.level_number,
  d.title as department,
  d.id as dept_id
FROM questions q
JOIN dept_levels dl ON dl.id = q.level_id
JOIN departments d ON d.id = dl.dept_id
WHERE q.description LIKE '%value-aligned%'
   OR q.title LIKE '%Value%'
ORDER BY q.title;

-- Check Orientation-Values department levels
SELECT 
  'ORIENTATION-VALUES LEVELS' as info,
  dl.id as level_id,
  dl.title as level_name,
  dl.level_number,
  d.title as department,
  COUNT(q.id) as question_count
FROM dept_levels dl
JOIN departments d ON d.id = dl.dept_id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.title = 'Orientation - Values'
GROUP BY dl.id, dl.title, dl.level_number, d.title
ORDER BY dl.level_number;
