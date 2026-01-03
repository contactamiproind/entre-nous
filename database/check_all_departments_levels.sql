-- Check which departments have questions and which need levels

-- Step 1: Check all departments and their current level status
SELECT 
  d.title as department,
  d.id as dept_id,
  jsonb_array_length(COALESCE(d.levels, '[]'::jsonb)) as level_count,
  COUNT(q.id) as question_count
FROM departments d
LEFT JOIN questions q ON d.id = q.dept_id
GROUP BY d.id, d.title, d.levels
ORDER BY question_count DESC;

-- Step 2: Show which departments have questions but no levels
SELECT 
  d.title as department,
  COUNT(q.id) as questions,
  jsonb_array_length(COALESCE(d.levels, '[]'::jsonb)) as levels
FROM departments d
LEFT JOIN questions q ON d.id = q.dept_id
GROUP BY d.id, d.title, d.levels
HAVING COUNT(q.id) > 0 AND jsonb_array_length(COALESCE(d.levels, '[]'::jsonb)) = 0
ORDER BY COUNT(q.id) DESC;
