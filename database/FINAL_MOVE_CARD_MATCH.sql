-- Move Card Match to the correct Mid level from JSONB

UPDATE questions
SET level_id = '760edfbb-949b-482f-b06d-1c606659a99a2'
WHERE id = 'a815eee1-e809-4571-8596-7500ce750e00';

-- Verify both questions are now correctly assigned
SELECT 
  'FINAL VERIFICATION' as info,
  q.id,
  q.title,
  q.level_id,
  dl.title as level_title,
  dl.level_number,
  CASE 
    WHEN dl.id IS NOT NULL THEN 'VALID ✓'
    ELSE 'ORPHANED ✗'
  END as status
FROM questions q
LEFT JOIN dept_levels dl ON dl.id = q.level_id
WHERE q.id IN ('90a720b3-ce61-44d9-8a93-c4ec2edd25a7', 'a815eee1-e809-4571-8596-7500ce750e00')
ORDER BY dl.level_number;

-- Double-check: simulate what the app will query
SELECT 
  'APP WILL SEE - EASY LEVEL' as info,
  q.*
FROM questions q
WHERE q.level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';

SELECT 
  'APP WILL SEE - MID LEVEL' as info,
  q.*
FROM questions q
WHERE q.level_id = '760edfbb-949b-482f-b06d-1c606599a99a2';
