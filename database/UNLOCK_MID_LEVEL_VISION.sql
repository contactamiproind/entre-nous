-- Check user progress and unlock Mid level for Orientation-Vision

-- Step 1: Check current user progress
SELECT 
  'USER PROGRESS' as info,
  u.email,
  up.user_id,
  d.title as department,
  up.current_level,
  up.total_score
FROM user_progress up
JOIN auth.users u ON u.id = up.user_id
JOIN departments d ON d.id = (
  SELECT pathway_id FROM user_pathway 
  WHERE user_id = up.user_id AND is_current = true 
  LIMIT 1
)
WHERE u.email = 'naik.abhira2326@gmail.com';

-- Step 2: Unlock Mid level by setting current_level to 2
UPDATE user_progress
SET current_level = 2
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'naik.abhira2326@gmail.com');

-- Step 3: Verify update
SELECT 
  'AFTER UNLOCK' as info,
  u.email,
  up.current_level,
  up.total_score
FROM user_progress up
JOIN auth.users u ON u.id = up.user_id
WHERE u.email = 'naik.abhira2326@gmail.com';
