-- SIMPLE FIX: Directly assign questions to the JSONB level IDs

-- From the browser console, we know the app is loading:
-- Easy level ID: f1e5977d-b3ff-4208-8b3c-cef90b7105d6
-- We need to find the Mid level ID from JSONB

-- Step 1: Show JSONB levels
SELECT 
  'JSONB LEVELS' as info,
  jsonb_pretty(levels) as levels_json
FROM departments
WHERE title = 'Orientation - Vision';

-- Step 2: Move Single Tap Choice to the Easy level the app is loading
UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6'
WHERE id = '90a720b3-ce61-44d9-8a93-c4ec2edd25a7';

-- Step 3: Find and move Card Match to Mid level from JSONB
-- First, let's see what the Mid level ID is
SELECT 
  'MID LEVEL FROM JSONB' as info,
  id,
  title,
  level_number
FROM dept_levels
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
  AND level_number = 2;

-- Step 4: Verify both questions are now assigned correctly
SELECT 
  'AFTER FIX' as info,
  q.id,
  q.title,
  q.level_id,
  dl.title as level_title,
  dl.level_number
FROM questions q
LEFT JOIN dept_levels dl ON dl.id = q.level_id
WHERE q.id IN ('90a720b3-ce61-44d9-8a93-c4ec2edd25a7', 'a815eee1-e809-4571-8596-7500ce750e00')
ORDER BY dl.level_number;
