-- Fix the Card Match question level_id to point to the correct Mid level
DO $$
DECLARE
  vision_dept_id UUID;
  mid_level_id UUID;
BEGIN
  -- Get Orientation - Vision department ID
  SELECT id INTO vision_dept_id FROM departments WHERE title = 'Orientation - Vision';
  
  -- Get the CURRENT Mid level ID (level_number = 2)
  SELECT id INTO mid_level_id 
  FROM dept_levels 
  WHERE dept_id = vision_dept_id AND level_number = 2;
  
  -- Update Card Match question to use correct level_id
  UPDATE questions
  SET level_id = mid_level_id
  WHERE title = 'Card Match' 
    AND dept_id = vision_dept_id;
  
  RAISE NOTICE 'Fixed Card Match question level_id';
  RAISE NOTICE 'New level_id: %', mid_level_id;
END $$;

-- Verify both questions now have correct level_ids
SELECT 
  q.title,
  q.description,
  q.level_id as current_level_id,
  dl.id as expected_level_id,
  dl.title as level_title,
  CASE WHEN q.level_id = dl.id THEN '✅ MATCH' ELSE '❌ MISMATCH' END as status
FROM questions q
JOIN departments d ON q.dept_id = d.id
JOIN dept_levels dl ON dl.dept_id = d.id
WHERE d.title = 'Orientation - Vision'
  AND (
    (q.title = 'Card Match' AND dl.level_number = 2) OR
    (q.title = 'Single Tap Choice' AND dl.level_number = 1)
  )
ORDER BY dl.level_number;
