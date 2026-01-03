-- Verify where the questions are NOW and what level IDs they have
SELECT 
  'CURRENT QUESTION LOCATION' as check_type,
  q.id,
  q.title,
  q.description,
  d.title as department,
  q.dept_id,
  q.level_id,
  dl.title as level_title,
  dl.level_number
FROM questions q
LEFT JOIN departments d ON q.dept_id = d.id
LEFT JOIN dept_levels dl ON q.level_id = dl.id
WHERE q.title IN ('Single Tap Choice', 'Card Match')
  AND (q.description LIKE '%Ease for a client%' OR q.description LIKE '%Ease vs Delight%')
ORDER BY q.title;

-- Check what level ID the app is querying and if it has questions
SELECT 
  'LEVEL APP IS QUERYING' as check_type,
  dl.id as level_id,
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  COUNT(q.id) as question_count,
  STRING_AGG(q.title, ', ') as questions
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE dl.id = 'f1ac997d-b3ff-4208-8b3c-cef90b7105d6'
GROUP BY dl.id, d.title, dl.level_number, dl.title;

-- Show ALL levels for the Vision department (0630caa4...)
SELECT 
  'ALL VISION DEPT LEVELS' as check_type,
  dl.id as level_id,
  dl.level_number,
  dl.title,
  COUNT(q.id) as questions
FROM dept_levels dl
LEFT JOIN questions q ON q.level_id = dl.id
WHERE dl.dept_id = '0630caa4-3087-4192-a6b4-20053c74e8f3'
GROUP BY dl.id, dl.level_number, dl.title
ORDER BY dl.level_number;
