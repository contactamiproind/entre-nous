-- Assign questions to the CURRENT Vision dept_levels that exist in database
DO $$
DECLARE
  vision_dept_id UUID := '0630caa4-3087-4192-a6b4-20053c74e8f3';
  current_easy_id UUID := '69748822-e974-4653-bd02-cba2ef9808d9';
  current_mid_id UUID := '2b33458d-c960-4d88-ac18-9d9c22eca62e';
BEGIN
  -- Assign "Single Tap Choice" to current Easy level
  UPDATE questions
  SET dept_id = vision_dept_id,
      level_id = current_easy_id,
      difficulty = 'easy'
  WHERE title = 'Single Tap Choice'
    AND description LIKE '%Ease for a client%';
  
  RAISE NOTICE 'Assigned Single Tap Choice to Easy level: %', current_easy_id;
  
  -- Assign "Card Match" to current Mid level
  UPDATE questions
  SET dept_id = vision_dept_id,
      level_id = current_mid_id,
      difficulty = 'medium'
  WHERE title = 'Card Match'
    AND description LIKE '%Ease vs Delight%';
  
  RAISE NOTICE 'Assigned Card Match to Mid level: %', current_mid_id;
END $$;

-- Verify both questions are now assigned
SELECT 
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  dl.id as level_id,
  COUNT(q.id) as questions,
  STRING_AGG(q.title, ', ') as question_titles
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.id = '0630caa4-3087-4192-a6b4-20053c74e8f3'
GROUP BY d.title, dl.level_number, dl.title, dl.id
ORDER BY dl.level_number;
