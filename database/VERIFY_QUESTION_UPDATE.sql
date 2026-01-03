-- Verify if the question was actually moved

SELECT 
  'CURRENT QUESTION ASSIGNMENT' as info,
  q.id,
  q.title,
  q.level_id as current_level_id,
  dl.title as level_title,
  dl.level_number,
  d.title as department
FROM questions q
LEFT JOIN dept_levels dl ON dl.id = q.level_id
LEFT JOIN departments d ON d.id = dl.dept_id
WHERE q.id = '90a720b3-ce61-44d9-8a93-c4ec2edd25a7';

-- Check if the level the app is querying actually exists
SELECT 
  'APP QUERYING LEVEL' as info,
  id,
  title,
  level_number,
  dept_id
FROM dept_levels
WHERE id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';

-- Check all questions for Orientation-Vision
SELECT 
  'ALL ORIENTATION-VISION QUESTIONS' as info,
  q.id,
  q.title,
  q.level_id,
  dl.level_number
FROM questions q
JOIN dept_levels dl ON dl.id = q.level_id
JOIN departments d ON d.id = dl.dept_id
WHERE d.title = 'Orientation - Vision'
ORDER BY dl.level_number;
