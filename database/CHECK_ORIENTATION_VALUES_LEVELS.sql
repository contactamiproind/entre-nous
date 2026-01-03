-- Find what dept_levels actually exist for Orientation-Values
-- and identify which one is Easy (level_number = 1)

SELECT 
  'ORIENTATION-VALUES ACTUAL LEVELS' as info,
  d.id as dept_id,
  d.title as department,
  dl.id as dept_level_id,
  dl.level_number,
  dl.title as level_title
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
WHERE d.title = 'Orientation - Values'
ORDER BY dl.level_number;

-- Check what the app is loading from departments.levels JSONB
SELECT 
  'DEPARTMENTS.LEVELS JSONB' as info,
  id,
  title,
  levels
FROM departments
WHERE title = 'Orientation - Values';
