-- Check pathway assignment for newtest@example.com

-- Step 1: Check if user exists in auth.users
SELECT id, email, created_at
FROM auth.users
WHERE email = 'newtest@example.com';

-- Step 2: Check if profile exists
SELECT user_id, email, role
FROM profiles
WHERE email = 'newtest@example.com';

-- Step 3: Check pathway assignments
SELECT 
  up.user_id,
  up.pathway_id,
  up.assigned_at,
  up.is_current,
  d.title as pathway_name
FROM user_pathway up
LEFT JOIN departments d ON up.pathway_id = d.id
WHERE up.user_id = (SELECT id FROM auth.users WHERE email = 'newtest@example.com');

-- Step 4: Check user progress
SELECT *
FROM user_progress
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'newtest@example.com');

-- Step 5: If no assignments found, manually assign Vision pathway
-- Uncomment and run if needed:
/*
INSERT INTO user_pathway (user_id, pathway_id, assigned_at, is_current, assigned_by)
SELECT 
  u.id,
  d.id,
  NOW(),
  true,
  u.id
FROM auth.users u
CROSS JOIN departments d
WHERE u.email = 'newtest@example.com'
  AND d.title = 'Vision';

-- Initialize user progress
INSERT INTO user_progress (user_id, current_pathway_id, current_level, completed_assignments, created_at, updated_at)
SELECT 
  u.id,
  d.id,
  1,
  0,
  NOW(),
  NOW()
FROM auth.users u
CROSS JOIN departments d
WHERE u.email = 'newtest@example.com'
  AND d.title = 'Vision';
*/
