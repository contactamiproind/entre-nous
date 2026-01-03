-- Remove Values and Goals, keep only Vision for user fe3c162a-0b43-4a79-bdff-d32234429781

-- Step 1: Check current assignments
SELECT 
  up.id,
  up.pathway_id,
  d.title as pathway_name
FROM user_pathway up
LEFT JOIN departments d ON up.pathway_id = d.id
WHERE up.user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781'
ORDER BY d.title;

-- Step 2: Delete Values and Goals assignments
DELETE FROM user_pathway
WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781'
  AND pathway_id IN (
    SELECT id FROM departments WHERE title IN ('Values', 'Goals')
  );

-- Step 3: Verify - should only have Vision
SELECT 
  up.id,
  up.pathway_id,
  d.title as pathway_name
FROM user_pathway up
LEFT JOIN departments d ON up.pathway_id = d.id
WHERE up.user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781';

-- Expected: 1 row (Vision only)
