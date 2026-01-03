-- Check what dept_levels ACTUALLY exist for Orientation-Values

SELECT 
  'DEPT_LEVELS FOR ORIENTATION-VALUES' as info,
  dl.id as dept_level_id,
  dl.title,
  dl.level_number,
  dl.dept_id,
  d.title as department
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.title = 'Orientation - Values'
ORDER BY dl.level_number;

-- Check what's in the JSONB
SELECT 
  'CURRENT JSONB' as info,
  id,
  title,
  levels
FROM departments
WHERE title = 'Orientation - Values';

-- Check if the level_id from console exists ANYWHERE
SELECT 
  'CONSOLE LEVEL EXISTS?' as info,
  dl.id,
  dl.title,
  d.title as department
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE dl.id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';
