-- Create entries in dept_levels table for all departments with questions
-- This creates the actual level records that questions can reference

DO $$
DECLARE
  dept RECORD;
BEGIN
  -- Loop through all departments that have questions
  FOR dept IN 
    SELECT DISTINCT
      d.id as dept_id,
      d.title as dept_title
    FROM departments d
    JOIN questions q ON d.id = q.dept_id
  LOOP
    -- Create 3 levels in dept_levels table for this department
    
    -- Easy Level
    INSERT INTO dept_levels (id, dept_id, level_number, title, category)
    VALUES (
      gen_random_uuid(),
      dept.dept_id,
      1,
      'Easy',
      'Introduction to ' || dept.dept_title
    );
    
    -- Medium Level
    INSERT INTO dept_levels (id, dept_id, level_number, title, category)
    VALUES (
      gen_random_uuid(),
      dept.dept_id,
      2,
      'Medium',
      'Understanding ' || dept.dept_title
    );
    
    -- Hard Level
    INSERT INTO dept_levels (id, dept_id, level_number, title, category)
    VALUES (
      gen_random_uuid(),
      dept.dept_id,
      3,
      'Hard',
      'Mastering ' || dept.dept_title
    );
    
    RAISE NOTICE 'Created dept_levels for: %', dept.dept_title;
  END LOOP;
  
  RAISE NOTICE 'All dept_levels created successfully!';
END $$;

-- Verify the creation
SELECT 
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  dl.category
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
ORDER BY d.title, dl.level_number;
