-- FINAL FIX: Move question to the level ID the app is loading

-- The app is loading level ID: f1e5977d-b3ff-4208-8b3c-cef90b7105d6 (from JSONB)
-- The question is assigned to: 8dd3422b-4714-428b-9a8b-bd05b6820683

-- Step 1: Verify the level the app is loading
SELECT 
  'APP LOADED LEVEL' as info,
  id,
  title,
  level_number,
  dept_id
FROM dept_levels
WHERE id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';

-- Step 2: Move the Vision question to this level
UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6'
WHERE id = '90a720b3-ce61-44d9-8a93-c4ec2edd25a7';

-- Step 3: Also check and move Card Match question for Mid level
-- First find the Mid level ID from JSONB (app is loading)
SELECT 
  'MID LEVEL CHECK' as info,
  dl.id,
  dl.title,
  dl.level_number,
  COUNT(q.id) as question_count
FROM dept_levels dl
LEFT JOIN questions q ON q.level_id = dl.id
WHERE dl.dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
  AND dl.level_number = 2
GROUP BY dl.id, dl.title, dl.level_number;

-- Step 4: Verify both questions are now assigned correctly
SELECT 
  'AFTER FIX' as info,
  q.id,
  q.title,
  q.level_id,
  dl.title as level_name,
  dl.level_number
FROM questions q
JOIN dept_levels dl ON dl.id = q.level_id
WHERE q.id IN ('90a720b3-ce61-44d9-8a93-c4ec2edd25a7', 'b0e8c483-960e-4b08-8886-bcf5923f91a1')
ORDER BY dl.level_number;
