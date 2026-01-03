-- Link Orientation - Vision questions to their dept_levels
-- First check the current state
SELECT 
  d.title as department,
  d.id as dept_id,
  dl.id as level_id,
  dl.level_number,
  dl.title as level_title,
  COUNT(q.id) as current_question_count
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON dl.id = q.level_id
WHERE d.title LIKE '%Vision%'
GROUP BY d.title, d.id, dl.id, dl.level_number, dl.title
ORDER BY dl.level_number;

-- Now link the questions
DO $$
DECLARE
  vision_dept_id UUID;
  level_1_id UUID;
  level_2_id UUID;
BEGIN
  -- Get Orientation - Vision department ID
  SELECT id INTO vision_dept_id 
  FROM departments 
  WHERE title LIKE '%Vision%';
  
  -- Get level IDs from dept_levels
  SELECT id INTO level_1_id 
  FROM dept_levels 
  WHERE dept_id = vision_dept_id AND level_number = 1;
  
  SELECT id INTO level_2_id 
  FROM dept_levels 
  WHERE dept_id = vision_dept_id AND level_number = 2;
  
  -- Update questions based on their difficulty
  UPDATE questions
  SET level_id = CASE 
    WHEN difficulty = 'easy' OR difficulty IS NULL THEN level_1_id
    WHEN difficulty = 'medium' OR difficulty = 'mid' THEN level_2_id
    ELSE level_1_id
  END
  WHERE dept_id = vision_dept_id;
  
  RAISE NOTICE 'Linked Orientation - Vision questions to levels!';
END $$;

-- Verify the update
SELECT 
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  COUNT(q.id) as question_count,
  STRING_AGG(q.difficulty, ', ') as difficulties
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON dl.id = q.level_id
WHERE d.title LIKE '%Vision%'
GROUP BY d.title, dl.level_number, dl.title
ORDER BY dl.level_number;
