-- Link questions to dept_levels (not the JSONB array in departments)
-- This uses the actual dept_levels table

DO $$
DECLARE
  dept RECORD;
  easy_level_id UUID;
  medium_level_id UUID;
  hard_level_id UUID;
BEGIN
  -- Loop through all departments
  FOR dept IN 
    SELECT DISTINCT d.id as dept_id, d.title
    FROM departments d
    JOIN questions q ON d.id = q.dept_id
  LOOP
    -- Get the level IDs from dept_levels table
    SELECT id INTO easy_level_id 
    FROM dept_levels 
    WHERE dept_id = dept.dept_id AND level_number = 1;
    
    SELECT id INTO medium_level_id 
    FROM dept_levels 
    WHERE dept_id = dept.dept_id AND level_number = 2;
    
    SELECT id INTO hard_level_id 
    FROM dept_levels 
    WHERE dept_id = dept.dept_id AND level_number = 3;
    
    -- Update questions for this department
    UPDATE questions
    SET level_id = CASE 
      WHEN difficulty = 'easy' OR difficulty IS NULL THEN easy_level_id
      WHEN difficulty = 'medium' THEN medium_level_id
      WHEN difficulty = 'hard' THEN hard_level_id
      ELSE easy_level_id
    END
    WHERE dept_id = dept.dept_id;
    
    RAISE NOTICE 'Linked questions for: %', dept.title;
  END LOOP;
  
  RAISE NOTICE 'All questions linked to dept_levels!';
END $$;

-- Verify the linkage
SELECT 
  d.title as department,
  dl.title as level_title,
  q.difficulty,
  COUNT(q.id) as question_count
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON dl.id = q.level_id
GROUP BY d.title, dl.title, q.difficulty
ORDER BY d.title, dl.title;
