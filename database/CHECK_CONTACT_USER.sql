-- Check specifically for contactam1pro1nd@gmail.com user

-- 1. Check if this user has a pathway assignment
SELECT 
  'CONTACT USER PATHWAY' as info,
  u.email,
  d.title as department,
  up.is_current,
  up.pathway_id
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
WHERE u.email = 'contactam1pro1nd@gmail.com';

-- 2. Check if this user has user_progress
SELECT 
  'CONTACT USER PROGRESS' as info,
  u.email,
  d.title as department,
  prog.current_level,
  prog.total_score,
  prog.current_pathway_id
FROM user_progress prog
JOIN auth.users u ON prog.user_id = u.id
LEFT JOIN departments d ON prog.current_pathway_id = d.id
WHERE u.email = 'contactam1pro1nd@gmail.com';

-- 3. If no records, check user ID
SELECT 
  'CONTACT USER ID' as info,
  id,
  email
FROM auth.users
WHERE email = 'contactam1pro1nd@gmail.com';
