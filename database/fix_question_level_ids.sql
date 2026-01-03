-- Step 1: Check if questions exist at all
SELECT COUNT(*) as total_questions FROM questions;

-- Step 2: Check what level_id values questions currently have
SELECT id, title, level_id, category
FROM questions
ORDER BY created_at
LIMIT 10;

-- Step 3: Check the actual level_id values from dept_levels for Orientation
SELECT id, level_id, title, level_number
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY level_number;

-- Step 4: Update questions to link to the correct level_id values
-- Based on the console output, the correct level_ids are:
-- Level 1 (Easy): 96deb175-cd50-49bb-a1b0-9e0c5c08415e
-- Level 2 (Mid): 26441bc0-e438-46d1-9508-209dd4aff8e2
-- Level 3 (Hard): bc61ee90-1541-41f9-ab87-eb0718b454e5
-- Level 4 (Extreme): 9119b3f5-e1cb-4d84-ac77-27c55030bc14

-- Update the first question to Easy level
UPDATE questions
SET level_id = '96deb175-cd50-49bb-a1b0-9e0c5c08415e'
WHERE id = (SELECT id FROM questions ORDER BY created_at LIMIT 1 OFFSET 0);

-- Update the second question to Mid level
UPDATE questions
SET level_id = '26441bc0-e438-46d1-9508-209dd4aff8e2'
WHERE id = (SELECT id FROM questions ORDER BY created_at LIMIT 1 OFFSET 1);

-- Update the third question to Hard level
UPDATE questions
SET level_id = 'bc61ee90-1541-41f9-ab87-eb0718b454e5'
WHERE id = (SELECT id FROM questions ORDER BY created_at LIMIT 1 OFFSET 2);

-- Update the fourth question to Extreme level
UPDATE questions
SET level_id = '9119b3f5-e1cb-4d84-ac77-27c55030bc14'
WHERE id = (SELECT id FROM questions ORDER BY created_at LIMIT 1 OFFSET 3);

-- Step 5: Verify the updates
SELECT q.id, q.title, q.level_id, dl.title as level_title, dl.level_number
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.level_id
WHERE dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number;
