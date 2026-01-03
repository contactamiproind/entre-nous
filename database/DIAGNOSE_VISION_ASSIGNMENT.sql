-- Check what's happening with Vision assignment

-- 1. Check user's assignment
SELECT 
  'USER ASSIGNMENT' as info,
  u.email,
  d.title as assigned_department,
  up.pathway_id
FROM auth.users u
JOIN user_pathway up ON up.user_id = u.id
JOIN departments d ON d.id = up.pathway_id
WHERE u.email = 'abhira232612@gmail.com';

-- 2. Check which department has "Orientation - Vision" title
SELECT 
  'VISION DEPARTMENTS' as info,
  id,
  title,
  jsonb_array_length(levels) as level_count
FROM departments
WHERE title LIKE '%Vision%'
ORDER BY title;

-- 3. Check Vision questions
SELECT 
  'VISION QUESTIONS' as info,
  q.id,
  q.title,
  q.description,
  dl.title as level_name,
  d.title as department
FROM questions q
JOIN dept_levels dl ON dl.id = q.level_id
JOIN departments d ON d.id = dl.dept_id
WHERE d.title LIKE '%Vision%'
ORDER BY dl.level_number;
