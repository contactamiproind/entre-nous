-- Find which department has the level ID the app is using
SELECT 
  'APP IS QUERYING' as info,
  d.title as department,
  dl.id as level_id,
  dl.level_number,
  dl.title as level_title,
  COUNT(q.id) as questions
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE dl.id = 'f1ac997d-b3ff-4208-8b3c-cef90b7105d6'
GROUP BY d.title, dl.id, dl.level_number, dl.title;

-- Show ALL dept_levels for Orientation - Vision
SELECT 
  'ORIENTATION-VISION LEVELS' as info,
  dl.id as level_id,
  dl.level_number,
  dl.title,
  COUNT(q.id) as questions
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.title = 'Orientation - Vision'
GROUP BY dl.id, dl.level_number, dl.title
ORDER BY dl.level_number;

-- Check if there are MULTIPLE Orientation - Vision departments
SELECT 
  id,
  title,
  description,
  created_at
FROM departments
WHERE title LIKE '%Vision%'
ORDER BY created_at;
