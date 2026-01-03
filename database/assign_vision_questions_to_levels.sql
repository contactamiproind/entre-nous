-- Check questions for Orientation - Vision and manually assign them
-- First, see what questions exist
SELECT 
  q.id,
  q.title,
  q.description,
  q.difficulty,
  q.level_id
FROM questions q
JOIN departments d ON q.dept_id = d.id
WHERE d.title = 'Orientation - Vision'
ORDER BY q.id;

-- Manually assign questions to Easy and Mid levels
DO $$
DECLARE
  easy_level_id UUID;
  mid_level_id UUID;
  vision_dept_id UUID;
BEGIN
  -- Get department ID
  SELECT id INTO vision_dept_id FROM departments WHERE title = 'Orientation - Vision';
  
  -- Get CURRENT level IDs from dept_levels table
  SELECT id INTO easy_level_id 
  FROM dept_levels 
  WHERE dept_id = vision_dept_id AND level_number = 1;
  
  SELECT id INTO mid_level_id 
  FROM dept_levels 
  WHERE dept_id = vision_dept_id AND level_number = 2;
  
  -- Assign "Single Tap Choice" question to Easy level
  UPDATE questions
  SET level_id = easy_level_id,
      difficulty = 'easy'
  WHERE dept_id = vision_dept_id 
    AND title = 'Single Tap Choice';
  
  RAISE NOTICE 'Assigned Single Tap Choice question to Easy level';
  
  -- Assign "Card Match" question to Mid level
  UPDATE questions
  SET level_id = mid_level_id,
      difficulty = 'medium'
  WHERE dept_id = vision_dept_id 
    AND title = 'Card Match';
  
  RAISE NOTICE 'Assigned Card Match question to Mid level';
END $$;

-- Verify the distribution
SELECT 
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  COUNT(q.id) as question_count,
  STRING_AGG(q.title, ', ') as question_titles
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON dl.id = q.level_id
WHERE d.title = 'Orientation - Vision'
GROUP BY d.title, dl.level_number, dl.title
ORDER BY dl.level_number;
