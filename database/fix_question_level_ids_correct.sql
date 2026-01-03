-- Fix question level_id values using the CORRECT UUIDs from the database
-- These are the actual level_id values from dept_levels table (verified from console output)

-- First, check current state
SELECT 'Current questions:' as status;
SELECT id, title, level_id FROM questions ORDER BY created_at;

SELECT 'Current dept_levels:' as status;
SELECT id, level_id, title, level_number 
FROM dept_levels 
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY level_number;

-- Update questions to use the CORRECT level_id values
-- These UUIDs are from the console output and match the actual database

-- Assuming we have 4 questions, link them to the 4 levels
-- You may need to adjust the question IDs based on what's actually in your database

-- Get the question IDs first (run this to see what questions exist)
SELECT id, title FROM questions ORDER BY created_at LIMIT 4;

-- Then update them one by one (replace the question IDs with actual IDs from above query)
-- For now, using a generic approach that updates by order

-- Update first 4 questions to the 4 orientation levels
WITH ordered_questions AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as rn
  FROM questions
  LIMIT 4
)
UPDATE questions
SET level_id = CASE 
  WHEN questions.id = (SELECT id FROM ordered_questions WHERE rn = 1) 
    THEN '96deb175-cd50-49bb-a1b0-9e0c5c08415e'  -- Easy
  WHEN questions.id = (SELECT id FROM ordered_questions WHERE rn = 2) 
    THEN '26441bc0-e438-46d1-9508-209dd4aff8e2'  -- Mid
  WHEN questions.id = (SELECT id FROM ordered_questions WHERE rn = 3) 
    THEN 'bc61ee90-1541-41f9-ab87-eb0718b454e5'  -- Hard
  WHEN questions.id = (SELECT id FROM ordered_questions WHERE rn = 4) 
    THEN '9119b3f5-e1cb-4d84-ac77-27c55030bc14'  -- Extreme
  ELSE level_id
END
WHERE id IN (SELECT id FROM ordered_questions);

-- Verify the updates worked
SELECT 'After update:' as status;
SELECT 
  q.id,
  q.title as question_title,
  q.level_id,
  dl.title as level_title,
  dl.level_number
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.level_id
WHERE dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number;
