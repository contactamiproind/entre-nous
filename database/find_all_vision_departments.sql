-- Find department with ID 7670b01f...
SELECT 
  id,
  title,
  description
FROM departments
WHERE id = '7670b01f-0d90-47e0-8d52-ff1a1f0e3fa5';

-- Find ALL departments with "Vision" in the name
SELECT 
  id,
  title,
  description,
  created_at
FROM departments
WHERE title LIKE '%Vision%'
ORDER BY created_at;

-- Check where our questions currently are
SELECT 
  q.title,
  q.description,
  d.title as department,
  q.dept_id,
  q.level_id,
  dl.title as level_title
FROM questions q
LEFT JOIN departments d ON q.dept_id = d.id
LEFT JOIN dept_levels dl ON q.level_id = dl.id
WHERE q.title IN ('Single Tap Choice', 'Card Match')
  AND (q.description LIKE '%Ease for a client%' OR q.description LIKE '%Ease vs Delight%')
ORDER BY q.title;
