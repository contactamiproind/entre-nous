-- Use EXACT IDs from the query results

-- Move Single Tap Choice to the Easy level the app is loading
UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6'
WHERE title = 'Single Tap Choice' 
  AND level_id = '8dd3422b-4714-428b-9a8b-bd05b6820683';

-- Verify the update worked
SELECT 
  'AFTER UPDATE' as info,
  id,
  title,
  level_id,
  CASE 
    WHEN level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6' THEN 'CORRECT EASY LEVEL ✓'
    WHEN level_id = '760edfbb-949b-482f-b06d-1c606659a99a' THEN 'CORRECT MID LEVEL ✓'
    ELSE 'WRONG LEVEL ✗'
  END as status
FROM questions
WHERE title IN ('Single Tap Choice', 'Card Match')
  AND level_id IN (
    'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    '760edfbb-949b-482f-b06d-1c606659a99a',
    '8dd3422b-4714-428b-9a8b-bd05b6820683'
  )
ORDER BY title;

-- Test what the app will see
SELECT 'APP EASY LEVEL' as info, COUNT(*) FROM questions WHERE level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';
SELECT 'APP MID LEVEL' as info, COUNT(*) FROM questions WHERE level_id = '760edfbb-949b-482f-b06d-1c606659a99a';
