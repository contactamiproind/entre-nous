-- Find which department the app is loading (simplified)
SELECT 
  d.id as dept_id,
  d.title as department,
  dl.id as level_id,
  dl.level_number,
  dl.title as level_title
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE dl.id = '69748822-e974-4653-bd02-cba2ef9808d9';
