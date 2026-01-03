-- Update using the exact ID from the query result

UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
WHERE description = 'Choose the most value-aligned action:';

-- Verify the update
SELECT 
  'AFTER UPDATE' as info,
  id,
  title,
  description,
  level_id,
  dept_id
FROM questions
WHERE description = 'Choose the most value-aligned action:';

-- Count questions in the target level
SELECT 
  'QUESTIONS IN ORIENTATION EASY' as info,
  COUNT(*) as count
FROM questions
WHERE level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';
