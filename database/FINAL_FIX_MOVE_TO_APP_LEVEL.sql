-- FINAL FIX: Move questions to the level ID the app is querying
-- App is querying: 69748822-e974-4653-bd02-cba2ef9808d9

-- Update "Single Tap Choice" (Easy question)
UPDATE questions
SET level_id = '69748822-e974-4653-bd02-cba2ef9808d9'
WHERE description = 'Which action best creates Ease for a client?';

-- Find and update "Card Match" (Mid question) to the Mid level of same department
UPDATE questions
SET level_id = (
  SELECT id FROM dept_levels 
  WHERE dept_id = (
    SELECT dept_id FROM dept_levels WHERE id = '69748822-e974-4653-bd02-cba2ef9808d9'
  )
  AND level_number = 2
  LIMIT 1
)
WHERE description = 'Ease vs Delight';

-- Verify both questions are now assigned
SELECT 
  q.title,
  q.description,
  q.level_id,
  dl.title as level_title,
  dl.level_number,
  d.title as department
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
JOIN departments d ON dl.dept_id = d.id
WHERE q.description IN ('Which action best creates Ease for a client?', 'Ease vs Delight')
ORDER BY dl.level_number;
