-- Fix Vision pathway by adding levels structure
-- This will create 3 levels: Easy, Medium, Hard for Vision pathway

-- First, get the Vision pathway ID
DO $$
DECLARE
  vision_id UUID;
BEGIN
  -- Get Vision department ID
  SELECT id INTO vision_id FROM departments WHERE title = 'Vision';
  
  -- Update the levels array in departments table
  UPDATE departments
  SET levels = jsonb_build_array(
    jsonb_build_object(
      'id', gen_random_uuid(),
      'name', 'Easy',
      'level_number', 1,
      'description', 'Introduction to Vision',
      'difficulty', 'easy'
    ),
    jsonb_build_object(
      'id', gen_random_uuid(),
      'name', 'Medium',
      'level_number', 2,
      'description', 'Understanding Vision',
      'difficulty', 'medium'
    ),
    jsonb_build_object(
      'id', gen_random_uuid(),
      'name', 'Hard',
      'level_number', 3,
      'description', 'Mastering Vision',
      'difficulty', 'hard'
    )
  )
  WHERE id = vision_id;
  
  RAISE NOTICE 'Vision pathway levels created successfully!';
END $$;

-- Verify the update
SELECT 
  title,
  jsonb_array_length(levels) as level_count,
  levels
FROM departments 
WHERE title = 'Vision';
