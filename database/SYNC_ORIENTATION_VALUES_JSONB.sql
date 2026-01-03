-- Sync Orientation-Values departments.levels JSONB with dept_levels table

UPDATE departments
SET levels = (
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', dl.id,
      'title', dl.title,
      'level_number', dl.level_number,
      'category', dl.category
    ) ORDER BY dl.level_number
  )
  FROM dept_levels dl
  WHERE dl.dept_id = departments.id
)
WHERE title = 'Orientation - Values';

-- Verify the sync
SELECT 
  'AFTER SYNC' as info,
  id,
  title,
  levels
FROM departments
WHERE title = 'Orientation - Values';

-- Also check the first level in the synced JSONB
SELECT 
  'EASY LEVEL FROM JSONB' as info,
  levels->0->>'id' as level_id,
  levels->0->>'title' as level_title,
  levels->0->>'level_number' as level_number
FROM departments
WHERE title = 'Orientation - Values';
