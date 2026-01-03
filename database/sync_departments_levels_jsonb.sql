-- Check the levels JSONB column in departments table for Vision
SELECT 
  id,
  title,
  levels
FROM departments
WHERE id = '0630caa4-3087-4192-a6b4-20053c74e8f3';

-- Update the levels JSONB to match current dept_levels
UPDATE departments
SET levels = (
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', dl.id,
      'dept_id', dl.dept_id,
      'level_id', dl.level_id,
      'title', dl.title,
      'category', dl.category,
      'level_number', dl.level_number,
      'created_at', dl.created_at,
      'updated_at', dl.updated_at
    ) ORDER BY dl.level_number
  )
  FROM dept_levels dl
  WHERE dl.dept_id = '0630caa4-3087-4192-a6b4-20053c74e8f3'
)
WHERE id = '0630caa4-3087-4192-a6b4-20053c74e8f3';

-- Verify the update
SELECT 
  id,
  title,
  levels
FROM departments
WHERE id = '0630caa4-3087-4192-a6b4-20053c74e8f3';
