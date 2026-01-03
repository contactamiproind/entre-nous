-- Move Vision questions to the correct "Orientation - Vision" pathway (32d2764f...)

-- First, check what levels exist in Orientation - Vision
SELECT 
  'ORIENTATION-VISION LEVELS' as info,
  id,
  level_number,
  title,
  category
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY level_number;

-- Move "Single Tap Choice" to Orientation - Vision Easy level
UPDATE questions
SET dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1',
    level_id = (
      SELECT id FROM dept_levels 
      WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1' 
        AND level_number = 1 
      LIMIT 1
    )
WHERE description = 'Which action best creates Ease for a client?';

-- Move "Card Match" to Orientation - Vision Mid level
UPDATE questions
SET dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1',
    level_id = (
      SELECT id FROM dept_levels 
      WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1' 
        AND level_number = 2 
      LIMIT 1
    )
WHERE description = 'Ease vs Delight';

-- Verify both questions are now in Orientation - Vision
SELECT 
  'VERIFICATION' as info,
  d.title as department,
  dl.level_number,
  dl.title as level,
  q.title as question,
  q.description
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
JOIN departments d ON dl.dept_id = d.id
WHERE q.description IN ('Which action best creates Ease for a client?', 'Ease vs Delight')
ORDER BY dl.level_number;
