-- Check which department abhira23261@gmail.com is assigned to

SELECT 
  'USER ASSIGNMENT' as info,
  u.email,
  d.id as dept_id,
  d.title as department,
  up.is_current
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
WHERE u.email = 'abhira23261@gmail.com';
