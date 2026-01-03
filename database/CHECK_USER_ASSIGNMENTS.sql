-- Check user assignments (FIXED - removed created_at references)

-- 1. Check all current user_pathway assignments
SELECT 
  'USER_PATHWAY ASSIGNMENTS' as info,
  u.email,
  d.title as department,
  up.is_current
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
ORDER BY u.email
LIMIT 10;

-- 2. Check user_progress for all users
SELECT 
  'USER_PROGRESS' as info,
  u.email,
  d.title as department,
  prog.current_level,
  prog.total_score
FROM user_progress prog
JOIN auth.users u ON prog.user_id = u.id
LEFT JOIN departments d ON prog.current_pathway_id = d.id
ORDER BY u.email
LIMIT 10;

-- 3. Check if there are any users with email containing 'contact'
SELECT 
  'CONTACT USERS' as info,
  id,
  email
FROM auth.users
WHERE email LIKE '%contact%'
ORDER BY email;

-- 4. Check ALL users to see who exists
SELECT 
  'ALL USERS' as info,
  id,
  email
FROM auth.users
ORDER BY email
LIMIT 20;
