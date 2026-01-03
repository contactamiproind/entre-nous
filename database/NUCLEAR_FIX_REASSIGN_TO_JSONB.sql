-- NUCLEAR OPTION: Delete old levels and reassign questions to JSONB levels

-- Step 1: Get the level IDs from JSONB (what the app loads)
SELECT 
  'JSONB LEVEL IDS' as info,
  jsonb_array_elements(levels)->>'id' as level_id,
  jsonb_array_elements(levels)->>'title' as title,
  (jsonb_array_elements(levels)->>'level_number')::int as level_number
FROM departments
WHERE title = 'Orientation - Vision'
ORDER BY level_number;

-- Step 2: Move Single Tap Choice to JSONB Easy level
UPDATE questions
SET level_id = (
  SELECT (jsonb_array_elements(levels)->>'id')::uuid
  FROM departments
  WHERE title = 'Orientation - Vision'
    AND (jsonb_array_elements(levels)->>'level_number')::int = 1
  LIMIT 1
)
WHERE id = '90a720b3-ce61-44d9-8a93-c4ec2edd25a7';

-- Step 3: Move Card Match to JSONB Mid level
UPDATE questions
SET level_id = (
  SELECT (jsonb_array_elements(levels)->>'id')::uuid
  FROM departments
  WHERE title = 'Orientation - Vision'
    AND (jsonb_array_elements(levels)->>'level_number')::int = 2
  LIMIT 1
)
WHERE id = 'a815eee1-e809-4571-8596-7500ce750e00';

-- Step 4: Delete old unused levels (not in JSONB)
DELETE FROM dept_levels
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
  AND id NOT IN (
    SELECT (jsonb_array_elements(levels)->>'id')::uuid
    FROM departments
    WHERE title = 'Orientation - Vision'
  );

-- Step 5: Verify final state
SELECT 
  'FINAL STATE' as info,
  q.id,
  q.title,
  q.level_id,
  dl.level_number,
  CASE 
    WHEN dl.id IS NOT NULL THEN 'VALID ✓'
    ELSE 'ORPHANED ✗'
  END as status
FROM questions q
LEFT JOIN dept_levels dl ON dl.id = q.level_id
WHERE q.id IN ('90a720b3-ce61-44d9-8a93-c4ec2edd25a7', 'a815eee1-e809-4571-8596-7500ce750e00')
ORDER BY dl.level_number;
