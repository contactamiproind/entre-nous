-- Find the department with ID 7670b01f that the app is loading
SELECT 
  'DEPT APP IS LOADING' as info,
  id,
  title,
  description,
  created_at
FROM departments
WHERE id = '7670b01f-0d90-47e0-8d52-ff1a1f0e3fa5';

-- Find ALL dept_levels for this department
SELECT 
  'LEVELS FOR 7670b01f DEPT' as info,
  dl.id as level_id,
  dl.level_number,
  dl.title,
  COUNT(q.id) as questions
FROM dept_levels dl
LEFT JOIN questions q ON q.level_id = dl.id
WHERE dl.dept_id = '7670b01f-0d90-47e0-8d52-ff1a1f0e3fa5'
GROUP BY dl.id, dl.level_number, dl.title
ORDER BY dl.level_number;

-- Check if user is somehow assigned to this department
SELECT 
  'USER ASSIGNMENTS' as info,
  up.pathway_id,
  d.title as pathway_name
FROM user_pathway up
JOIN departments d ON up.pathway_id = d.id
WHERE up.user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781';
