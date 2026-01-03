-- Check ALL pathway assignments for abhira123@gmail.com

SELECT 
  u.email,
  d.title as pathway_name,
  up.assigned_at,
  up.is_current,
  up.assigned_by
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
LEFT JOIN departments d ON up.pathway_id = d.id
WHERE u.email = 'abhira123@gmail.com'
ORDER BY up.assigned_at;
