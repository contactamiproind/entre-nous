-- Check if the question was actually updated

SELECT 
  'QUESTION CURRENT STATE' as info,
  id,
  title,
  level_id,
  dept_id
FROM questions
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e838';

-- Check if this level_id exists in dept_levels
SELECT 
  'LEVEL EXISTS' as info,
  dl.id,
  dl.title,
  dl.level_number,
  d.title as department
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE dl.id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';
