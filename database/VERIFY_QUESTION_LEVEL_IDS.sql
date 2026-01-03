-- Check what level_id values the questions actually have
SELECT 
  'QUESTIONS LEVEL_ID VALUES' as info,
  q.title,
  q.description,
  q.level_id as question_level_id,
  q.dept_id
FROM questions q
WHERE q.description IN ('Which action best creates Ease for a client?', 'Ease vs Delight');

-- Check what level_id values exist in dept_levels for Orientation-Vision
SELECT 
  'DEPT_LEVELS FOR ORIENTATION-VISION' as info,
  dl.id as dept_levels_id,
  dl.level_id as master_level_id,
  dl.level_number,
  dl.title,
  d.title as department
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number;

-- Check if there's a mismatch
SELECT 
  'MISMATCH CHECK' as info,
  'Question level_id does NOT match any dept_levels.level_id' as issue
WHERE EXISTS (
  SELECT 1 FROM questions q
  WHERE q.description IN ('Which action best creates Ease for a client?', 'Ease vs Delight')
    AND NOT EXISTS (
      SELECT 1 FROM dept_levels dl
      WHERE dl.level_id = q.level_id
        AND dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
    )
);
