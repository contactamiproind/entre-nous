-- Check if Vision questions are linked to the correct level ID

-- 1. What level ID does the app load for "Orientation - Vision" Easy?
SELECT 
  'ORIENTATION-VISION EASY LEVEL' as info,
  id,
  title,
  dept_id
FROM dept_levels
WHERE id = '86d3422b-4714-428b-9a8b-bd85b6820683';

-- 2. What questions are linked to this level?
SELECT 
  'QUESTIONS FOR THIS LEVEL' as info,
  id,
  title,
  description
FROM questions
WHERE level_id = '86d3422b-4714-428b-9a8b-bd85b6820683';

-- 3. Where are the Vision questions actually linked?
SELECT 
  'VISION QUESTIONS CURRENT LOCATION' as info,
  q.title,
  q.level_id,
  dl.title as level_name,
  d.title as department
FROM questions q
JOIN dept_levels dl ON dl.id = q.level_id
JOIN departments d ON d.id = dl.dept_id
WHERE q.title IN ('Single Tap Choice', 'Card Match')
  AND q.description LIKE '%Ease%'
ORDER BY q.title;
