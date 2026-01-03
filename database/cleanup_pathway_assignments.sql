-- Comprehensive cleanup of user_pathway table
-- Remove NULLs, duplicates, and old Orientation pathways

-- Step 1: Delete NULL pathway_id entries
DELETE FROM user_pathway
WHERE pathway_id IS NULL;

-- Step 2: Delete old "Orientation" pathway entries
DELETE FROM user_pathway
WHERE pathway_name LIKE 'Orientation%';

-- Step 3: Check for any remaining duplicates
SELECT 
  user_id,
  pathway_id,
  COUNT(*) as duplicate_count
FROM user_pathway
GROUP BY user_id, pathway_id
HAVING COUNT(*) > 1;

-- Step 4: If duplicates exist, keep only the earliest assignment
DELETE FROM user_pathway a
USING user_pathway b
WHERE a.id > b.id
  AND a.user_id = b.user_id
  AND a.pathway_id = b.pathway_id;

-- Step 5: Final verification - show clean data
SELECT 
  up.id,
  up.user_id,
  up.pathway_id,
  d.title as pathway_name,
  up.assigned_at
FROM user_pathway up
LEFT JOIN departments d ON up.pathway_id = d.id
ORDER BY up.user_id, d.title;

-- Step 6: Count per user
SELECT 
  user_id,
  COUNT(*) as pathways_assigned
FROM user_pathway
GROUP BY user_id;
