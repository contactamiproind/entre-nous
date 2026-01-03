-- Move Single Tap Choice to the correct Easy level that the app is loading

UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6'
WHERE id = '90a720b3-ce01-44d9-8a93-c4ec2edd25a7';

-- Verify both questions are now on correct levels
SELECT 
  'FINAL CHECK' as info,
  q.id,
  q.title,
  q.level_id,
  dl.level_number,
  CASE 
    WHEN q.level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6' THEN 'EASY (APP LEVEL) ✓'
    WHEN q.level_id = '760edfbb-949b-482f-b06d-1c606659a99a' THEN 'MID (APP LEVEL) ✓'
    ELSE 'WRONG LEVEL ✗'
  END as status
FROM questions q
LEFT JOIN dept_levels dl ON dl.id = q.level_id
WHERE q.id IN ('90a720b3-ce01-44d9-8a93-c4ec2edd25a7', 'a815eee1-e809-4571-8596-7500ce750e00')
ORDER BY dl.level_number;
