-- Re-sync all departments' JSONB after cleanup

UPDATE departments d
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
  WHERE dl.dept_id = d.id
)
WHERE EXISTS (
  SELECT 1 FROM dept_levels WHERE dept_id = d.id
);

-- Verify sync for Vision, Goals, Values departments
SELECT 
  'JSONB SYNC VERIFICATION' as info,
  d.title as department,
  jsonb_array_length(d.levels) as jsonb_level_count,
  COUNT(dl.id) as actual_level_count,
  CASE 
    WHEN jsonb_array_length(d.levels) = COUNT(dl.id) THEN 'SYNCED ✓'
    ELSE 'MISMATCH ✗'
  END as status
FROM departments d
LEFT JOIN dept_levels dl ON dl.dept_id = d.id
WHERE d.title LIKE '%Vision%' OR d.title LIKE '%Goals%' OR d.title LIKE '%Values%'
GROUP BY d.id, d.title, d.levels
ORDER BY d.title;
