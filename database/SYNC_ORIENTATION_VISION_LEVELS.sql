-- Update the departments.levels JSONB column for Orientation - Vision
-- to match the actual dept_levels in the database

-- First, check current state
SELECT 
  'CURRENT STATE' as info,
  id,
  title,
  levels
FROM departments
WHERE id = '32d2764f-ed76-40db-8886-bcf5923f91a1';

-- Update the levels JSONB to match actual dept_levels
UPDATE departments
SET levels = (
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', dl.id,
      'title', dl.title,
      'dept_id', dl.dept_id,
      'level_number', dl.level_number,
      'category', dl.category,
      'created_at', dl.created_at,
      'updated_at', dl.updated_at
    ) ORDER BY dl.level_number
  )
  FROM dept_levels dl
  WHERE dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
)
WHERE id = '32d2764f-ed76-40db-8886-bcf5923f91a1';

-- Verify the update
SELECT 
  'UPDATED STATE' as info,
  id,
  title,
  levels
FROM departments
WHERE id = '32d2764f-ed76-40db-8886-bcf5923f91a1';

-- Show the level IDs that should now be in the JSONB
SELECT 
  'ACTUAL DEPT_LEVELS' as info,
  id as level_id,
  level_number,
  title,
  category
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY level_number;
