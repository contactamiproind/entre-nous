-- Update the ACTUAL Values question to Orientation Easy level (FIXED UUID)

UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
WHERE id = 'da1599b2-a455-4802-b0f5-fafdde35fecd';

-- Verify the update
SELECT 
  'AFTER UPDATE' as info,
  id,
  title,
  description,
  level_id,
  dept_id
FROM questions
WHERE id = 'da1599b2-a455-4802-b0f5-fafdde35fecd';

-- Verify it shows up in the level query
SELECT 
  'LEVEL QUERY' as info,
  id,
  title,
  description
FROM questions
WHERE level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';
