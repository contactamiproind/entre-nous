-- Assign multiple pathways to abhira123@gmail.com
-- This will assign: Vision, Values, and Brand Guidelines

-- Step 1: Clear existing assignments
DELETE FROM user_pathway
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'abhira123@gmail.com');

-- Step 2: Assign Vision pathway (has 2 questions)
INSERT INTO user_pathway (user_id, pathway_id, assigned_at, is_current, assigned_by)
SELECT 
  u.id,
  d.id,
  NOW(),
  true,  -- Set Vision as current pathway
  u.id
FROM auth.users u
CROSS JOIN departments d
WHERE u.email = 'abhira123@gmail.com'
  AND d.title = 'Vision';

-- Step 3: Assign Values pathway (has 1 question)
INSERT INTO user_pathway (user_id, pathway_id, assigned_at, is_current, assigned_by)
SELECT 
  u.id,
  d.id,
  NOW(),
  false,  -- Not current, but assigned
  u.id
FROM auth.users u
CROSS JOIN departments d
WHERE u.email = 'abhira123@gmail.com'
  AND d.title = 'Values';

-- Step 4: Assign Brand Guidelines pathway (has 1 question)
INSERT INTO user_pathway (user_id, pathway_id, assigned_at, is_current, assigned_by)
SELECT 
  u.id,
  d.id,
  NOW(),
  false,  -- Not current, but assigned
  u.id
FROM auth.users u
CROSS JOIN departments d
WHERE u.email = 'abhira123@gmail.com'
  AND d.title = 'Orientation - Brand Guidelines';

-- Step 5: Initialize user progress for Vision (current pathway)
DELETE FROM user_progress 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'abhira123@gmail.com');

INSERT INTO user_progress (user_id, current_pathway_id, current_level, completed_assignments, created_at, updated_at)
SELECT 
  u.id,
  d.id,
  1,  -- Start at level 1
  0,
  NOW(),
  NOW()
FROM auth.users u
CROSS JOIN departments d
WHERE u.email = 'abhira123@gmail.com'
  AND d.title = 'Vision';

-- Step 6: Verify all assignments
SELECT 
  u.email,
  d.title as pathway_name,
  up.is_current,
  up.assigned_at
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
LEFT JOIN departments d ON up.pathway_id = d.id
WHERE u.email = 'abhira123@gmail.com'
ORDER BY up.is_current DESC, d.title;

-- Expected result: 3 pathways assigned
-- - Vision (is_current = true)
-- - Values (is_current = false)
-- - Orientation - Brand Guidelines (is_current = false)
