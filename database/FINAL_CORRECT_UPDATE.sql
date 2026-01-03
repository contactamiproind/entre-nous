-- Update with the CORRECT question ID (with the 9 at the end)

UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e839';

-- Verify the update
SELECT 
  'AFTER UPDATE' as info,
  id,
  title,
  level_id,
  dept_id
FROM questions
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e839';

-- Verify it shows up in the level query
SELECT 
  'LEVEL QUERY - SHOULD SHOW QUESTION' as info,
  COUNT(*) as question_count
FROM questions
WHERE level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';
