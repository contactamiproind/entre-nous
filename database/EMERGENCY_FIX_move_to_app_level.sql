-- EMERGENCY FIX: Move questions to the exact level ID the app is querying
-- App is querying: f1e5977d-b3ff-4208-8b3c-cef90b7105d6

-- Move "Single Tap Choice" question to the level app is querying
UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45',
    difficulty = 'easy'
WHERE title = 'Single Tap Choice'
  AND description LIKE '%Ease for a client%';

-- Move "Card Match" question to Mid level of same department
UPDATE questions
SET level_id = (
  SELECT id FROM dept_levels 
  WHERE dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45' 
    AND level_number = 2 
  LIMIT 1
),
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45',
    difficulty = 'medium'
WHERE title = 'Card Match'
  AND description LIKE '%Ease vs Delight%';

-- Verify both questions are now linked
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
WHERE q.title IN ('Single Tap Choice', 'Card Match')
  AND (q.description LIKE '%Ease for a client%' OR q.description LIKE '%Ease vs Delight%')
ORDER BY dl.level_number;
