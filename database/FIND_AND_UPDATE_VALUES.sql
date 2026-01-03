-- Find the ACTUAL Easy level ID from dept_levels table

SELECT 
  'ACTUAL EASY LEVEL' as info,
  dl.id as dept_level_id,
  dl.title as level_title,
  dl.level_number,
  d.title as department,
  d.id as dept_id
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.title = 'Orientation - Values'
  AND dl.level_number = 1
ORDER BY dl.id
LIMIT 1;

-- Update question to this actual Easy level
UPDATE questions
SET level_id = (
  SELECT dl.id
  FROM dept_levels dl
  JOIN departments d ON dl.dept_id = d.id
  WHERE d.title = 'Orientation - Values'
    AND dl.level_number = 1
  ORDER BY dl.id
  LIMIT 1
)
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e838';

-- Verify
SELECT 
  'AFTER UPDATE' as info,
  q.title as question,
  q.level_id,
  dl.title as level_title,
  d.title as department
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
JOIN departments d ON dl.dept_id = d.id
WHERE q.id = '28c7f67c-5f45-49a2-8636-32991284e838';
