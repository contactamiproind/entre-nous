-- Find the ACTUAL Orientation-Vision level IDs from dept_levels table

SELECT 
  'ACTUAL ORIENTATION-VISION LEVELS' as info,
  dl.id,
  dl.title,
  dl.level_number,
  d.title as department,
  d.id as dept_id
FROM dept_levels dl
JOIN departments d ON d.id = dl.dept_id
WHERE d.title = 'Orientation - Vision'
ORDER BY dl.level_number;
