-- Link existing Vision questions to the newly created levels

-- First, check current state of Vision questions
SELECT 
  q.id,
  q.title,
  q.dept_id,
  q.level_id,
  q.difficulty
FROM questions q
WHERE q.dept_id = (SELECT id FROM departments WHERE title = 'Vision');

-- Get the level IDs from Vision pathway's levels array
SELECT 
  title,
  jsonb_array_elements(levels)->>'id' as level_id,
  jsonb_array_elements(levels)->>'name' as level_name,
  jsonb_array_elements(levels)->>'difficulty' as difficulty
FROM departments
WHERE title = 'Vision';

-- Update questions to link them to the appropriate Vision levels
-- We'll distribute questions across the 3 levels based on their difficulty
DO $$
DECLARE
  vision_dept_id UUID;
  easy_level_id UUID;
  medium_level_id UUID;
  hard_level_id UUID;
BEGIN
  -- Get Vision department ID
  SELECT id INTO vision_dept_id FROM departments WHERE title = 'Vision';
  
  -- Extract level IDs from the levels JSONB array
  SELECT (levels->0->>'id')::uuid INTO easy_level_id 
  FROM departments WHERE title = 'Vision';
  
  SELECT (levels->1->>'id')::uuid INTO medium_level_id 
  FROM departments WHERE title = 'Vision';
  
  SELECT (levels->2->>'id')::uuid INTO hard_level_id 
  FROM departments WHERE title = 'Vision';
  
  -- Update questions based on difficulty
  -- If no difficulty is set, assign to Easy level
  UPDATE questions
  SET level_id = CASE 
    WHEN difficulty = 'easy' OR difficulty IS NULL THEN easy_level_id
    WHEN difficulty = 'medium' THEN medium_level_id
    WHEN difficulty = 'hard' THEN hard_level_id
    ELSE easy_level_id
  END
  WHERE dept_id = vision_dept_id;
  
  RAISE NOTICE 'Vision questions linked to levels successfully!';
END $$;

-- Verify the update
SELECT 
  q.title,
  q.difficulty,
  q.level_id,
  d.title as department
FROM questions q
JOIN departments d ON q.dept_id = d.id
WHERE d.title = 'Vision';
