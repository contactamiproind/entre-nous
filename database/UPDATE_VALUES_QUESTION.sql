-- Update Values question to the FIRST Easy level found

-- Update the Single Tap Choice question to Orientation-Values Easy level
UPDATE questions
SET level_id = (
  SELECT dl.id 
  FROM dept_levels dl
  WHERE dl.dept_id = '2390ec7d-15ea-45b6-903a-b1c1e7bbbcd2'
    AND dl.level_number = 1
  ORDER BY dl.id
  LIMIT 1
)
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e838';

-- Verify the update worked
SELECT 
  'AFTER UPDATE' as info,
  q.title as question,
  q.level_id,
  dl.title as level_title,
  dl.level_number,
  d.title as department
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
JOIN departments d ON dl.dept_id = d.id
WHERE q.id = '28c7f67c-5f45-49a2-8636-32991284e838';
