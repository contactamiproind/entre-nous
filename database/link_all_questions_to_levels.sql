-- Link ALL questions to their department's levels
-- This updates level_id for all questions based on their difficulty

DO $$
DECLARE
  dept RECORD;
  easy_level_id UUID;
  medium_level_id UUID;
  hard_level_id UUID;
BEGIN
  -- Loop through all departments that have levels
  FOR dept IN 
    SELECT 
      d.id,
      d.title,
      d.levels
    FROM departments d
    WHERE jsonb_array_length(COALESCE(d.levels, '[]'::jsonb)) > 0
  LOOP
    -- Extract level IDs from the levels JSONB array
    easy_level_id := (dept.levels->0->>'id')::uuid;
    medium_level_id := (dept.levels->1->>'id')::uuid;
    hard_level_id := (dept.levels->2->>'id')::uuid;
    
    -- Update questions for this department
    UPDATE questions
    SET level_id = CASE 
      WHEN difficulty = 'easy' OR difficulty IS NULL THEN easy_level_id
      WHEN difficulty = 'medium' THEN medium_level_id
      WHEN difficulty = 'hard' THEN hard_level_id
      ELSE easy_level_id
    END
    WHERE dept_id = dept.id;
    
    RAISE NOTICE 'Linked questions for department: %', dept.title;
  END LOOP;
  
  RAISE NOTICE 'All questions linked to levels!';
END $$;

-- Verify the update - show questions per department and level
SELECT 
  d.title as department,
  q.difficulty,
  COUNT(q.id) as question_count,
  COUNT(DISTINCT q.level_id) as unique_levels_used
FROM departments d
JOIN questions q ON d.id = q.dept_id
GROUP BY d.title, q.difficulty
ORDER BY d.title, q.difficulty;

-- Summary by department
SELECT 
  d.title as department,
  jsonb_array_length(d.levels) as total_levels,
  COUNT(q.id) as total_questions,
  COUNT(DISTINCT q.level_id) as levels_with_questions
FROM departments d
LEFT JOIN questions q ON d.id = q.dept_id
GROUP BY d.id, d.title, d.levels
HAVING COUNT(q.id) > 0
ORDER BY d.title;
