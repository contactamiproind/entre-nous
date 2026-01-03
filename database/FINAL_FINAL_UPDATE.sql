-- Update with the ACTUAL CORRECT question ID (ends with 039)

UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e039';

-- Verify the update
SELECT 
  'AFTER UPDATE' as info,
  id,
  title,
  description,
  level_id,
  dept_id
FROM questions
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e039';

-- Verify it shows up in the level query
SELECT 
  'LEVEL QUERY - COUNT' as info,
  COUNT(*) as question_count
FROM questions
WHERE level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';
