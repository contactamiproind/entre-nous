-- Check user assignment and fix if needed

-- 1. Check current assignment for abhira23261@gmail.com
SELECT 
  'CURRENT ASSIGNMENT' as info,
  u.email,
  d.title as assigned_department,
  d.id as dept_id,
  up.is_current
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
WHERE u.email = 'abhira23261@gmail.com';

-- 2. Find the correct "Orientation - Values" department ID
SELECT 
  'ORIENTATION-VALUES DEPT' as info,
  id,
  title
FROM departments
WHERE title = 'Orientation - Values';

-- 3. Update user assignment to correct department if needed
-- (We'll do this after seeing the results)
