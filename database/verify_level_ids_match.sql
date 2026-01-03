-- Check what dept_levels.id the app should be querying
SELECT 
  dl.id as dept_level_id,
  dl.level_number,
  dl.title as level_title,
  d.title as department,
  COUNT(q.id) as question_count,
  STRING_AGG(q.id::text, ', ') as question_ids,
  STRING_AGG(q.description, ' | ') as questions
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.title = 'Orientation - Vision'
GROUP BY dl.id, dl.level_number, dl.title, d.title
ORDER BY dl.level_number;

-- Also check if questions have the correct level_id
SELECT 
  q.id,
  q.title,
  q.description,
  q.level_id,
  dl.id as expected_level_id,
  dl.title as level_title,
  CASE WHEN q.level_id = dl.id THEN 'MATCH ✅' ELSE 'MISMATCH ❌' END as status
FROM questions q
JOIN departments d ON q.dept_id = d.id
LEFT JOIN dept_levels dl ON dl.dept_id = d.id AND dl.level_number = 1
WHERE d.title = 'Orientation - Vision';
