-- Move questions from old "Orientation - Vision" to new "Vision" department
DO $$
DECLARE
  old_vision_id UUID := '32d2764f-cd76-40db-8886-bcf5923f91a1'; -- Orientation - Vision
  new_vision_id UUID := '0630caa4-3087-4192-a6b4-20053c74e8f3'; -- Vision
  new_easy_level_id UUID;
  new_mid_level_id UUID;
BEGIN
  -- Get the level IDs from the NEW Vision department
  SELECT id INTO new_easy_level_id
  FROM dept_levels
  WHERE dept_id = new_vision_id AND level_number = 1;
  
  SELECT id INTO new_mid_level_id
  FROM dept_levels
  WHERE dept_id = new_vision_id AND level_number = 2;
  
  -- Move "Single Tap Choice" question to new Vision Easy level
  UPDATE questions
  SET dept_id = new_vision_id,
      level_id = new_easy_level_id
  WHERE title = 'Single Tap Choice'
    AND description LIKE '%Ease for a client%';
  
  -- Move "Card Match" question to new Vision Mid level
  UPDATE questions
  SET dept_id = new_vision_id,
      level_id = new_mid_level_id
  WHERE title = 'Card Match'
    AND description LIKE '%Ease vs Delight%';
  
  RAISE NOTICE 'Moved questions to new Vision department';
  RAISE NOTICE 'Easy level ID: %', new_easy_level_id;
  RAISE NOTICE 'Mid level ID: %', new_mid_level_id;
END $$;

-- Verify the questions are now in the correct department
SELECT 
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  dl.id as level_id,
  COUNT(q.id) as questions,
  STRING_AGG(q.description, ' | ') as question_list
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.id = '0630caa4-3087-4192-a6b4-20053c74e8f3'
GROUP BY d.title, dl.level_number, dl.title, dl.id
ORDER BY dl.level_number;
