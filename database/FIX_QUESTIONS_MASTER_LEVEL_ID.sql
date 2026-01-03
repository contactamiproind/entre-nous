-- CORRECT FIX: Update questions to use dept_levels.id (not level_id)
-- The FK constraint requires questions.level_id to reference dept_levels.id

-- Update "Single Tap Choice" to Easy level of Orientation-Vision
UPDATE questions
SET level_id = (
  SELECT id FROM dept_levels 
  WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1' 
    AND level_number = 1 
  LIMIT 1
),
    dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
WHERE description = 'Which action best creates Ease for a client?';

-- Update "Card Match" to Mid level of Orientation-Vision
UPDATE questions
SET level_id = (
  SELECT id FROM dept_levels 
  WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1' 
    AND level_number = 2 
  LIMIT 1
),
    dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
WHERE description = 'Ease vs Delight';

-- Verify the update
SELECT 
  'VERIFICATION' as info,
  q.title,
  q.description,
  q.level_id,
  dl.id as dept_levels_id,
  dl.title as level_title,
  dl.level_number,
  d.title as department
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
JOIN departments d ON dl.dept_id = d.id
WHERE q.description IN ('Which action best creates Ease for a client?', 'Ease vs Delight')
ORDER BY dl.level_number;
