-- Fix ALL departments that have questions but no levels
-- This creates 3 levels (Easy, Medium, Hard) for each department with questions

DO $$
DECLARE
  dept RECORD;
BEGIN
  -- Loop through all departments that have questions but no levels
  FOR dept IN 
    SELECT 
      d.id,
      d.title
    FROM departments d
    LEFT JOIN questions q ON d.id = q.dept_id
    GROUP BY d.id, d.title, d.levels
    HAVING COUNT(q.id) > 0 
      AND jsonb_array_length(COALESCE(d.levels, '[]'::jsonb)) = 0
  LOOP
    -- Create 3 levels for this department
    UPDATE departments
    SET levels = jsonb_build_array(
      jsonb_build_object(
        'id', gen_random_uuid(),
        'name', 'Easy',
        'level_number', 1,
        'description', 'Introduction to ' || dept.title,
        'difficulty', 'easy'
      ),
      jsonb_build_object(
        'id', gen_random_uuid(),
        'name', 'Medium',
        'level_number', 2,
        'description', 'Understanding ' || dept.title,
        'difficulty', 'medium'
      ),
      jsonb_build_object(
        'id', gen_random_uuid(),
        'name', 'Hard',
        'level_number', 3,
        'description', 'Mastering ' || dept.title,
        'difficulty', 'hard'
      )
    )
    WHERE id = dept.id;
    
    RAISE NOTICE 'Created levels for department: %', dept.title;
  END LOOP;
  
  RAISE NOTICE 'All departments with questions now have levels!';
END $$;

-- Verify the update
SELECT 
  d.title as department,
  jsonb_array_length(d.levels) as level_count,
  COUNT(q.id) as question_count
FROM departments d
LEFT JOIN questions q ON d.id = q.dept_id
GROUP BY d.id, d.title, d.levels
HAVING COUNT(q.id) > 0
ORDER BY d.title;
