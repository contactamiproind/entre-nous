-- Redistribute questions across Vision, Values, and Goals pathways
-- Assuming you have 3 separate departments or 3 levels within Orientation

-- First, check what departments/pathways you have
SELECT id, name FROM departments ORDER BY name;

-- Option 1: If Vision, Values, Goals are separate DEPARTMENTS
-- You'll need to find their department IDs and corresponding level IDs

-- Option 2: If they are LEVELS within Orientation department
-- Check the levels in Orientation
SELECT id, level_id, title, level_number, dept_id
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY level_number;

-- Based on your current setup (4 levels: Easy, Mid, Hard, Extreme),
-- you might want to rename them to Vision, Values, Goals, or create new ones

-- SOLUTION 1: Rename existing levels to Vision, Values, Goals
-- Keep 4 levels but rename them
UPDATE dept_levels 
SET title = 'Vision'
WHERE id = '9853367f-6104-4354-8990-d9968348b1f6'; -- Level 1 (Easy)

UPDATE dept_levels 
SET title = 'Vision'  
WHERE id = 'e4f9a22e-54bc-493f-92e6-e995dda84e65'; -- Level 2 (Mid) - Also Vision for 2nd question

UPDATE dept_levels 
SET title = 'Values'
WHERE id = '8353c78f-bea9-4a5b-baeb-2b15af51276d'; -- Level 3 (Hard)

UPDATE dept_levels 
SET title = 'Goals'
WHERE id = '47069cd1-a395-4f7f-a322-23eefc7b1e0e'; -- Level 4 (Extreme)

-- Now verify the distribution
SELECT 
  q.description as question,
  dl.title as pathway_level,
  dl.level_number
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
WHERE dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number;

-- This will give you:
-- Question 1 → Vision (Level 1)
-- Question 2 → Vision (Level 2)  
-- Question 3 → Values (Level 3)
-- Question 4 → Goals (Level 4)
