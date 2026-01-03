-- Reassign abhira123@gmail.com from "Orientation - Brand Guidelines" to "Vision"

-- Step 1: Delete current assignment
DELETE FROM user_pathway
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'abhira123@gmail.com');

-- Step 2: Assign to Vision pathway
INSERT INTO user_pathway (user_id, pathway_id, assigned_at, is_current, assigned_by)
SELECT 
  u.id,
  d.id,
  NOW(),
  true,
  u.id
FROM auth.users u
CROSS JOIN departments d
WHERE u.email = 'abhira123@gmail.com'
  AND d.title = 'Vision';

-- Step 3: Initialize/update user progress for Vision
DELETE FROM user_progress 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'abhira123@gmail.com');

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
WHERE u.email = 'abhira123@gmail.com'
  AND d.title = 'Vision';

-- Step 4: Verify
SELECT 
  u.email,
  d.title as pathway_name,
  up.assigned_at
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
WHERE u.email = 'abhira123@gmail.com';
