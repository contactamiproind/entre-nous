-- Find Orientation-Values dept_levels and match with question

-- 1. Get Orientation-Values department and its levels
SELECT 
  'ORIENTATION-VALUES LEVELS' as info,
  d.id as dept_id,
  d.title as department,
  dl.id as dept_level_id,
  dl.level_number,
  dl.title as level_title
FROM departments d
LEFT JOIN dept_levels dl ON d.id = dl.dept_id
WHERE d.id = '2390ec7d-15ea-45b6-903a-b1c1e7bbbcd2'
ORDER BY dl.level_number;

-- 2. Check what level_id the question currently has
SELECT 
  'CURRENT QUESTION ASSIGNMENT' as info,
  q.id as question_id,
  q.title,
  q.level_id,
  q.dept_id
FROM questions q
WHERE q.id = '28c7f67c-5f45-49a2-8636-32991284e838';

-- 3. Update question to point to Orientation-Values Easy level
UPDATE questions
SET level_id = (
  SELECT dl.id 
  FROM dept_levels dl
  WHERE dl.dept_id = '2390ec7d-15ea-45b6-903a-b1c1e7bbbcd2'
    AND dl.level_number = 1
  LIMIT 1
)
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e838';

-- 4. Verify the update
SELECT 
  'VERIFICATION' as info,
  q.title as question,
  d.title as department,
  dl.title as level_title,
  dl.id as dept_level_id
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
JOIN departments d ON dl.dept_id = d.id
WHERE q.id = '28c7f67c-5f45-49a2-8636-32991284e838';
