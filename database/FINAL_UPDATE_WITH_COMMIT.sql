-- Update Values question to Orientation Easy level and COMMIT

BEGIN;

UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e838';

COMMIT;

-- Verify the update persisted
SELECT 
  'AFTER COMMIT' as info,
  id,
  title,
  level_id,
  dept_id
FROM questions
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e838';

-- Verify it shows up in the level query
SELECT 
  'LEVEL QUERY' as info,
  id,
  title,
  level_id
FROM questions
WHERE level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';
