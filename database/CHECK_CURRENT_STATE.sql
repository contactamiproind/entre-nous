-- Check current state of questions and dept_levels

-- 1. What level_id do the questions currently have?
SELECT 
  'CURRENT QUESTION STATE' as info,
  q.title,
  q.description,
  q.level_id as current_level_id,
  q.dept_id as current_dept_id
FROM questions q
WHERE q.description IN ('Which action best creates Ease for a client?', 'Ease vs Delight');

-- 2. What dept_levels.id values exist for Orientation-Vision?
SELECT 
  'ORIENTATION-VISION DEPT_LEVELS' as info,
  dl.id as dept_levels_id,
  dl.level_number,
  dl.title,
  dl.category,
  d.title as department
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number;

-- 3. Check if questions match any dept_levels.id
SELECT 
  'MATCH CHECK' as info,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM questions q
      JOIN dept_levels dl ON q.level_id = dl.id
      WHERE q.description IN ('Which action best creates Ease for a client?', 'Ease vs Delight')
        AND dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
    ) THEN 'Questions ARE linked to Orientation-Vision levels ✅'
    ELSE 'Questions are NOT linked to Orientation-Vision levels ❌'
  END as status;
