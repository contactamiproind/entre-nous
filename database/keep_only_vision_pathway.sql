-- Remove Values and Goals pathway assignments for ALL users, keep only Vision

-- Step 1: Check current state - how many users have pathway assignments
SELECT 
  COUNT(DISTINCT user_id) as total_users,
  COUNT(*) as total_assignments
FROM user_pathway;

-- Step 2: See breakdown by pathway
SELECT 
  d.title as pathway_name,
  COUNT(*) as assignment_count
FROM user_pathway up
LEFT JOIN departments d ON up.pathway_id = d.id
GROUP BY d.title
ORDER BY d.title;

-- Step 3: Delete Values and Goals assignments for ALL users (keep only Vision)
DELETE FROM user_pathway
WHERE pathway_id IN (
  SELECT id FROM departments WHERE title IN ('Values', 'Goals')
);

-- Step 4: Verify - should only have Vision assignments remaining
SELECT 
  up.user_id,
  d.title as pathway_name,
  up.assigned_at
FROM user_pathway up
LEFT JOIN departments d ON up.pathway_id = d.id
ORDER BY up.user_id, d.title;

-- Step 5: Count remaining assignments
SELECT 
  COUNT(DISTINCT user_id) as users_with_vision,
  COUNT(*) as total_vision_assignments
FROM user_pathway up
LEFT JOIN departments d ON up.pathway_id = d.id
WHERE d.title = 'Vision';
