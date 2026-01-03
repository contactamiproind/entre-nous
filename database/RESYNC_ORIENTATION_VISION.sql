-- Re-sync Orientation-Vision JSONB after assigning questions

UPDATE departments
SET levels = (
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', dl.id,
      'title', dl.title,
      'level_number', dl.level_number,
      'category', dl.category,
      'created_at', dl.created_at,
      'updated_at', dl.updated_at
    ) ORDER BY dl.level_number
  )
  FROM dept_levels dl
  WHERE dl.dept_id = departments.id
)
WHERE title = 'Orientation - Vision';

-- Verify sync
SELECT 
  'JSONB SYNC CHECK' as info,
  title,
  jsonb_array_length(levels) as jsonb_count,
  (SELECT COUNT(*) FROM dept_levels WHERE dept_id = departments.id) as actual_count,
  CASE 
    WHEN jsonb_array_length(levels) = (SELECT COUNT(*) FROM dept_levels WHERE dept_id = departments.id) 
    THEN 'SYNCED ✓'
    ELSE 'MISMATCH ✗'
  END as status
FROM departments
WHERE title = 'Orientation - Vision';
