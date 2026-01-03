-- Both questions should be in Orientation department (7670bb1f-0d90-47e6-8d52-ff141fb63f45)

-- Assign "Which action best creates Ease for a client?" to Orientation Easy level
UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45',
    difficulty = 'easy'
WHERE description = 'Which action best creates Ease for a client?';

-- Assign "Ease vs Delight" to Orientation Mid level (NOT Vision!)
UPDATE questions
SET level_id = '2b33458d-c960-4d88-ac18-9d9c22eca62e',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45',
    difficulty = 'medium'
WHERE description = 'Ease vs Delight';

-- Verify both are now in Orientation department
SELECT 
  q.description,
  q.level_id,
  dl.title as level_title,
  dl.level_number,
  d.id as dept_id,
  d.title as department
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
JOIN departments d ON dl.dept_id = d.id
WHERE q.description IN ('Which action best creates Ease for a client?', 'Ease vs Delight')
ORDER BY dl.level_number;
