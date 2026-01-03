-- FINAL COMPREHENSIVE FIX
-- This creates a clean pathway structure based on what exists

-- Step 1: Find which pathways have questions
WITH pathway_summary AS (
  SELECT 
    d.id,
    d.title,
    COUNT(DISTINCT dl.id) as level_count,
    COUNT(q.id) as question_count
  FROM departments d
  LEFT JOIN dept_levels dl ON d.id = dl.dept_id
  LEFT JOIN questions q ON q.level_id = dl.id
  GROUP BY d.id, d.title
)
SELECT * FROM pathway_summary WHERE question_count > 0 ORDER BY title;

-- Step 2: For the pathway the app is currently loading (Orientation - 7670bb1f...)
-- Ensure it has exactly 2 levels and the correct questions

-- Keep only the levels the app is using
DELETE FROM dept_levels
WHERE dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
  AND id NOT IN (
    'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',  -- Easy level app is using
    '2b33458d-c960-4d88-ac18-9d9c22eca62e'   -- Mid level app is using
  );

-- Assign the Vision questions to this pathway
UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
WHERE description = 'Which action best creates Ease for a client?';

UPDATE questions
SET level_id = '2b33458d-c960-4d88-ac18-9d9c22eca62e',
    dept_id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
WHERE description = 'Ease vs Delight';

-- Step 3: Verify the fix
SELECT 
  'FINAL STATE' as info,
  d.title as pathway,
  dl.level_number,
  dl.title as level,
  dl.id as level_id,
  COUNT(q.id) as questions,
  STRING_AGG(q.description, ' | ') as question_descriptions
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45'
GROUP BY d.title, dl.level_number, dl.title, dl.id
ORDER BY dl.level_number;
