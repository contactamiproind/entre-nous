-- Debug: Check current state and try update with explicit transaction

BEGIN;

-- Show current state
SELECT 
  'BEFORE UPDATE' as info,
  id,
  title,
  level_id
FROM questions
WHERE title = 'Single Tap Choice';

-- Try the update
UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6'
WHERE title = 'Single Tap Choice';

-- Show after state
SELECT 
  'AFTER UPDATE' as info,
  id,
  title,
  level_id
FROM questions
WHERE title = 'Single Tap Choice';

-- Commit the transaction
COMMIT;

-- Final verification
SELECT 'EASY LEVEL COUNT' as info, COUNT(*) as count FROM questions WHERE level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';
SELECT 'MID LEVEL COUNT' as info, COUNT(*) as count FROM questions WHERE level_id = '760edfbb-949b-482f-b06d-1c606659a99a';
