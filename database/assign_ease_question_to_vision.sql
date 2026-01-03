-- Assign the "Which action best creates Ease for a client?" question to Orientation - Vision Easy level

DO $$
DECLARE
  vision_dept_id UUID;
  easy_level_id UUID;
  question_id UUID := '90a72bb3-ce01-44d0-8a93-c4ec2edd25a7'; -- ID from screenshot
BEGIN
  -- Get Orientation - Vision department ID
  SELECT id INTO vision_dept_id FROM departments WHERE title = 'Orientation - Vision';
  
  -- Get Easy level ID
  SELECT id INTO easy_level_id 
  FROM dept_levels 
  WHERE dept_id = vision_dept_id AND level_number = 1;
  
  -- Update the question to belong to Orientation - Vision Easy level
  UPDATE questions
  SET dept_id = vision_dept_id,
      level_id = easy_level_id,
      difficulty = 'easy'
  WHERE description LIKE '%Which action best creates Ease for a client%';
  
  RAISE NOTICE 'Assigned "Which action best creates Ease for a client?" to Orientation - Vision Easy level';
END $$;

-- Verify the result
SELECT 
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  COUNT(q.id) as question_count,
  STRING_AGG(q.description, ' | ') as questions
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON dl.id = q.level_id
WHERE d.title = 'Orientation - Vision'
GROUP BY d.title, dl.level_number, dl.title
ORDER BY dl.level_number;
