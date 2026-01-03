-- Check which department has the level ID the app is using
SELECT 
  'APP IS USING THIS LEVEL' as info,
  d.title as department,
  dl.id as level_id,
  dl.level_number,
  dl.title as level_title,
  COUNT(q.id) as question_count
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE dl.id = '69748822-e974-4653-bd02-cba2ef9808d9'
GROUP BY d.title, dl.id, dl.level_number, dl.title;

-- Check what pathway this user is actually assigned to
SELECT 
  'USER ASSIGNMENT' as info,
  u.email,
  d.title as assigned_pathway,
  up.pathway_id,
  up.is_current
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
WHERE u.id = 'fe3c162a-0b43-4a79-bdff-d32234429781';

-- Check if "Vision" and "Orientation - Vision" are different departments
SELECT 
  id,
  title,
  description
FROM departments
WHERE title LIKE '%Vision%'
ORDER BY title;
