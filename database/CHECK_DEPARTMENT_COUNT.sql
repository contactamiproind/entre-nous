-- Check actual department count and list all departments

SELECT 
  'TOTAL DEPARTMENT COUNT' as info,
  COUNT(*) as total_departments
FROM departments;

-- List all departments
SELECT 
  'ALL DEPARTMENTS' as info,
  id,
  title,
  category,
  (SELECT COUNT(*) FROM user_pathway WHERE pathway_id = departments.id) as user_count,
  (SELECT COUNT(*) FROM dept_levels WHERE dept_id = departments.id) as level_count
FROM departments
ORDER BY title;
