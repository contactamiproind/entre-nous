-- Fix Orientation-Values: Remove duplicate levels and assign Values question

-- Step 1: Find all duplicate levels in Orientation-Values
SELECT 
  'DUPLICATE LEVELS IN ORIENTATION-VALUES' as info,
  level_number,
  COUNT(*) as duplicate_count,
  array_agg(id::text) as level_ids
FROM dept_levels
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Values')
GROUP BY level_number
HAVING COUNT(*) > 1
ORDER BY level_number;

-- Step 2: Keep only one level per level_number (keep the first one, delete others)
WITH duplicates AS (
  SELECT 
    id,
    level_number,
    ROW_NUMBER() OVER (PARTITION BY dept_id, level_number ORDER BY created_at) as rn
  FROM dept_levels
  WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Values')
)
DELETE FROM dept_levels
WHERE id IN (
  SELECT id FROM duplicates WHERE rn > 1
);

-- Step 3: Find the Values question
SELECT 
  'VALUES QUESTION' as info,
  id,
  title,
  description,
  level_id as current_level_id,
  dept_id as current_dept_id
FROM questions
WHERE description LIKE '%value-aligned%';

-- Step 4: Move Values question to Orientation-Values Easy level
UPDATE questions
SET 
  level_id = (
    SELECT id FROM dept_levels 
    WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Values')
      AND level_number = 1
    LIMIT 1
  ),
  dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Values')
WHERE description LIKE '%value-aligned%';

-- Step 5: Verify fix
SELECT 
  'AFTER FIX - ORIENTATION-VALUES LEVELS' as info,
  dl.id,
  dl.title,
  dl.level_number,
  COUNT(q.id) as question_count
FROM dept_levels dl
LEFT JOIN questions q ON q.level_id = dl.id
WHERE dl.dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Values')
GROUP BY dl.id, dl.title, dl.level_number
ORDER BY dl.level_number;
