-- Get the EXACT level IDs (copy-paste safe)

SELECT 
  id::text as level_id,
  title,
  level_number,
  dept_id::text as dept_id
FROM dept_levels dl
WHERE dept_id IN (
  SELECT id FROM departments WHERE title = 'Orientation - Vision'
)
ORDER BY level_number;
