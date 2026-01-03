-- First, let's see what level_ids the questions currently have
SELECT id, title, level_id, category, subcategory
FROM questions
WHERE level_id IS NOT NULL
ORDER BY created_at;

-- Then, let's see what level_ids exist for the Orientation pathway
SELECT level_id, level_number, title, dept_id
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY level_number;

-- We need to match questions to the correct levels
-- This will help us create the UPDATE statements to link them properly
