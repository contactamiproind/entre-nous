-- Check for duplicate Easy levels in Orientation-Vision

SELECT 
  'ALL EASY LEVELS FOR ORIENTATION-VISION' as info,
  dl.id,
  dl.level_id as master_level_id,
  dl.title,
  dl.level_number,
  d.title as department,
  COUNT(q.id) as question_count
FROM dept_levels dl
JOIN departments d ON d.id = dl.dept_id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.title = 'Orientation - Vision'
  AND dl.level_number = 1
GROUP BY dl.id, dl.level_id, dl.title, dl.level_number, d.title;

-- Check what's in the JSONB
SELECT 
  'JSONB LEVELS' as info,
  title,
  jsonb_pretty(levels) as levels_json
FROM departments
WHERE title = 'Orientation - Vision';

-- Check where the question is actually assigned
SELECT 
  'QUESTION ASSIGNMENT' as info,
  q.id as question_id,
  q.title,
  q.level_id as assigned_to_level_id,
  dl.title as level_title,
  dl.level_number
FROM questions q
LEFT JOIN dept_levels dl ON dl.id = q.level_id
WHERE q.id = '90a720b3-ce61-44d9-8a93-c4ec2edd25a7';
