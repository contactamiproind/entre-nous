-- Delete the wrong "Single Tap Choice" questions (keep only "Which action best creates Ease for a client?")
DELETE FROM questions
WHERE title = 'Single Tap Choice'
  AND description NOT LIKE '%Ease for a client%';

-- Ensure the correct "Single Tap Choice" is assigned to the right level
UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
WHERE title = 'Single Tap Choice'
  AND description LIKE '%Ease for a client%';

-- Ensure "Card Match" is assigned to the right level
UPDATE questions
SET level_id = '2b33458d-c960-4d88-ac18-9d9c22eca62e',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
WHERE title = 'Card Match'
  AND description LIKE '%Ease vs Delight%';

-- Verify final state
SELECT 
  q.id,
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
