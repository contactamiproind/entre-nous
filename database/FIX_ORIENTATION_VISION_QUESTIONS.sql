-- Fix Orientation-Vision: Assign Vision questions to correct levels

-- Step 1: Find Vision questions and their current location
SELECT 
  'VISION QUESTIONS CURRENT LOCATION' as info,
  q.id,
  q.title,
  q.description,
  q.level_id as current_level_id,
  dl.title as current_level_name,
  d.title as current_department
FROM questions q
LEFT JOIN dept_levels dl ON dl.id = q.level_id
LEFT JOIN departments d ON d.id = dl.dept_id
WHERE q.description LIKE '%Ease%' OR q.title = 'Card Match'
ORDER BY q.title;

-- Step 2: Get Orientation-Vision level IDs
SELECT 
  'ORIENTATION-VISION LEVEL IDS' as info,
  id,
  title,
  level_number
FROM dept_levels
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
ORDER BY level_number;

-- Step 3: Move "Single Tap Choice" (Ease) to Orientation-Vision Easy
UPDATE questions
SET 
  level_id = (
    SELECT id FROM dept_levels 
    WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
      AND level_number = 1
    LIMIT 1
  ),
  dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
WHERE description LIKE '%Ease%' AND title = 'Single Tap Choice';

-- Step 4: Move "Card Match" to Orientation-Vision Mid
UPDATE questions
SET 
  level_id = (
    SELECT id FROM dept_levels 
    WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
      AND level_number = 2
    LIMIT 1
  ),
  dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
WHERE title = 'Card Match';

-- Step 5: Verify fix
SELECT 
  'AFTER FIX - ORIENTATION-VISION LEVELS' as info,
  dl.id,
  dl.title,
  dl.level_number,
  COUNT(q.id) as question_count,
  array_agg(q.title) FILTER (WHERE q.id IS NOT NULL) as questions
FROM dept_levels dl
LEFT JOIN questions q ON q.level_id = dl.id
WHERE dl.dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
GROUP BY dl.id, dl.title, dl.level_number
ORDER BY dl.level_number;
