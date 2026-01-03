-- Find which department the app is actually loading
SELECT 
  'DEPARTMENT APP IS LOADING' as info,
  id,
  title,
  description,
  created_at
FROM departments
WHERE id = '7670b01f-0d90-47e0-8d52-ff1a1f0e3fa5';

-- Find which department has the level ID the app is querying
SELECT 
  'LEVEL APP IS QUERYING' as info,
  d.id as dept_id,
  d.title as department,
  dl.id as level_id,
  dl.level_number,
  dl.title as level_title,
  COUNT(q.id) as questions
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE dl.id = 'f1ac997d-b3ff-4208-8b3c-cef90b7105d6'
GROUP BY d.id, d.title, dl.id, dl.level_number, dl.title;

-- Check what pathway this user is ACTUALLY assigned to
SELECT 
  'USER ACTUAL ASSIGNMENT' as info,
  up.pathway_id,
  d.title as pathway_name,
  up.is_current
FROM user_pathway up
JOIN departments d ON up.pathway_id = d.id
WHERE up.user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781'
  AND up.is_current = true;
