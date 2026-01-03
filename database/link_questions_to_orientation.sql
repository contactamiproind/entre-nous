-- Link questions to Orientation pathway levels
-- Based on the level titles: Easy, Mid, Hard, Extreme

-- First, let's see what questions we have
SELECT id, title, level_id, category, subcategory
FROM questions
WHERE level_id IS NOT NULL
ORDER BY created_at;

-- Update questions to link to correct Orientation levels
-- Assuming we want to distribute the 4 questions across the 4 levels

-- Option 1: If questions should go to specific levels based on difficulty
-- You'll need to manually match them. For now, let's assign one question per level:

-- Question 1 → Level 1 (Easy)
-- Question 2 → Level 2 (Mid)  
-- Question 3 → Level 3 (Hard)
-- Question 4 → Level 4 (Extreme)

-- IMPORTANT: Run the SELECT first to see the question IDs,
-- then uncomment and run the UPDATE statements below with the correct question IDs

/*
UPDATE questions
SET level_id = '96deb175-cd50-49bb-a1ba-9e8bc5d8415e'  -- Level 1 (Easy)
WHERE id = 'REPLACE_WITH_QUESTION_1_ID';

UPDATE questions
SET level_id = '26441bc8-e436-46d1-9588-2b9dd4aff8e2'  -- Level 2 (Mid)
WHERE id = 'REPLACE_WITH_QUESTION_2_ID';

UPDATE questions
SET level_id = 'bc61ee98-1541-41f9-ab87-eb8718b454e5'  -- Level 3 (Hard)
WHERE id = 'REPLACE_WITH_QUESTION_3_ID';

UPDATE questions
SET level_id = '9119b3f5-e1cb-4d84-ac77-27c65630bc14'  -- Level 4 (Extreme)
WHERE id = 'REPLACE_WITH_QUESTION_4_ID';
*/

-- After updating, verify the link:
SELECT 
  q.id,
  q.title as question_title,
  dl.level_number,
  dl.title as level_title
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.level_id
WHERE dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number;
