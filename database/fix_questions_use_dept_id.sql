-- SIMPLE FIX: Use dept_levels.id instead of dept_levels.level_id
-- The foreign key constraint expects values that exist in the referenced table

-- First, let's see what we're working with
SELECT 'Questions table:' as info;
SELECT id, title, level_id FROM questions ORDER BY created_at LIMIT 5;

SELECT 'Dept_levels IDs (use these for level_id):' as info;
SELECT id, level_id, title, level_number
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY level_number;

-- Now update questions to use dept_levels.ID (not level_id)
-- These are the correct IDs from the console output

WITH ordered_questions AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as rn
  FROM questions
  LIMIT 4
)
UPDATE questions
SET level_id = CASE 
  WHEN questions.id = (SELECT id FROM ordered_questions WHERE rn = 1) 
    THEN '9853367f-6104-4354-8990-d9968348b1f6'  -- Easy (dept_levels.id)
  WHEN questions.id = (SELECT id FROM ordered_questions WHERE rn = 2) 
    THEN 'e4f9a22e-54bc-493f-92e6-e995dda84e65'  -- Mid (dept_levels.id)
  WHEN questions.id = (SELECT id FROM ordered_questions WHERE rn = 3) 
    THEN '8353c78f-bea9-4a5b-baeb-2b15af51276d'  -- Hard (dept_levels.id)
  WHEN questions.id = (SELECT id FROM ordered_questions WHERE rn = 4) 
    THEN '47069cd1-a395-4f7f-a322-23eefc7b1e0e'  -- Extreme (dept_levels.id)
  ELSE level_id
END
WHERE id IN (SELECT id FROM ordered_questions);

-- Verify
SELECT 'After update - linked questions:' as info;
SELECT 
  q.id,
  q.title as question_title,
  q.level_id,
  dl.title as level_title,
  dl.level_number
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
WHERE dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number;
