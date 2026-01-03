-- STEP 1: Clean up existing duplicates FIRST
-- This must run before adding constraints

WITH duplicates AS (
  SELECT 
    id,
    dept_id,
    level_number,
    ROW_NUMBER() OVER (PARTITION BY dept_id, level_number ORDER BY created_at) as rn
  FROM dept_levels
)
DELETE FROM dept_levels
WHERE id IN (
  SELECT id FROM duplicates WHERE rn > 1
);

-- Verify duplicates are gone
SELECT 
  'DUPLICATE CHECK' as info,
  dept_id,
  level_number,
  COUNT(*) as count
FROM dept_levels
GROUP BY dept_id, level_number
HAVING COUNT(*) > 1;
