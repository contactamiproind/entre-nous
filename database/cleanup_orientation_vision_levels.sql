-- Clean up Orientation - Vision dept_levels and keep only Easy and Mid

-- Step 1: Check current questions before cleanup
SELECT 
  q.id,
  q.title,
  q.difficulty,
  q.level_id
FROM questions q
JOIN departments d ON q.dept_id = d.id
WHERE d.title = 'Orientation - Vision';

-- Step 2: Delete ALL dept_levels for Orientation - Vision
DELETE FROM dept_levels
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision');

-- Step 3: Create exactly 2 levels (Easy and Mid)
DO $$
DECLARE
  vision_dept_id UUID;
  easy_level_id UUID;
  mid_level_id UUID;
BEGIN
  -- Get department ID
  SELECT id INTO vision_dept_id FROM departments WHERE title = 'Orientation - Vision';
  
  -- Create Easy level
  INSERT INTO dept_levels (id, dept_id, level_number, title, category)
  VALUES (
    gen_random_uuid(),
    vision_dept_id,
    1,
    'Easy',
    'Introduction to Orientation - Vision'
  )
  RETURNING id INTO easy_level_id;
  
  -- Create Mid level
  INSERT INTO dept_levels (id, dept_id, level_number, title, category)
  VALUES (
    gen_random_uuid(),
    vision_dept_id,
    2,
    'Mid',
    'Understanding Orientation - Vision'
  )
  RETURNING id INTO mid_level_id;
  
  -- Link questions to levels based on difficulty
  UPDATE questions
  SET level_id = CASE 
    WHEN difficulty = 'easy' OR difficulty IS NULL THEN easy_level_id
    WHEN difficulty = 'medium' OR difficulty = 'mid' THEN mid_level_id
    ELSE easy_level_id
  END
  WHERE dept_id = vision_dept_id;
  
  RAISE NOTICE 'Created 2 levels and linked questions for Orientation - Vision';
END $$;

-- Step 4: Verify the result
SELECT 
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  COUNT(q.id) as question_count,
  STRING_AGG(q.difficulty, ', ') as difficulties
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON dl.id = q.level_id
WHERE d.title = 'Orientation - Vision'
GROUP BY d.title, dl.level_number, dl.title
ORDER BY dl.level_number;
