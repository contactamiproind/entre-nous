-- Simple check: What department is the user assigned to and what does the app load?

-- 1. User's assignment
SELECT 
  'USER ASSIGNMENT' as info,
  u.email,
  up.pathway_id,
  d.title as department_title
FROM auth.users u
JOIN user_pathway up ON up.user_id = u.id
JOIN departments d ON d.id = up.pathway_id
WHERE u.email = 'abhira232612@gmail.com';

-- 2. What departments have "Vision" in the title?
SELECT 
  'ALL VISION DEPARTMENTS' as info,
  id,
  title
FROM departments
WHERE title LIKE '%Vision%'
ORDER BY title;

-- 3. What's in the user's assigned department's levels JSONB?
SELECT 
  'ASSIGNED DEPT LEVELS JSONB' as info,
  d.title,
  d.levels
FROM auth.users u
JOIN user_pathway up ON up.user_id = u.id
JOIN departments d ON d.id = up.pathway_id
WHERE u.email = 'abhira232612@gmail.com';
