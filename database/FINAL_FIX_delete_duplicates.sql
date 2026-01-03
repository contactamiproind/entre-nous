-- COMPREHENSIVE FIX: Delete ALL duplicate dept_levels and keep only the ones the app is currently using

-- Step 1: Identify the level IDs the app is using (from console logs)
-- Easy: f1e5977d-b3ff-4208-8b3c-cef90b7105d6
-- Mid: 2b33458d-c960-4d88-ac18-9d9c22eca62e

-- Step 2: Delete ALL other dept_levels for Orientation department EXCEPT these two
DELETE FROM dept_levels
WHERE dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
  AND id NOT IN (
    'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',  -- Easy
    '2b33458d-c960-4d88-ac18-9d9c22eca62e'   -- Mid (the one app is currently using)
  );

-- Step 3: Verify only 2 levels remain
SELECT 
  id,
  level_number,
  title,
  category
FROM dept_levels
WHERE dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
ORDER BY level_number;

-- Step 4: Ensure questions are assigned to these exact levels
UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
WHERE title = 'Single Tap Choice'
  AND description LIKE '%Ease for a client%';

UPDATE questions
SET level_id = '2b33458d-c960-4d88-ac18-9d9c22eca62e',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
WHERE title = 'Card Match'
  AND description LIKE '%Ease vs Delight%';

-- Step 5: Verify questions are correctly assigned
SELECT 
  q.title,
  q.level_id,
  dl.title as level_title,
  dl.level_number
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
WHERE q.title IN ('Single Tap Choice', 'Card Match')
ORDER BY dl.level_number;
