-- CORRECTED: Assign users to Vision, Values, Goals pathways
-- Using WHERE NOT EXISTS to avoid ON CONFLICT errors

-- Step 1: Check current user pathway assignments
SELECT 
  up.user_id,
  d.title as pathway_title,
  up.assigned_at
FROM user_pathway up
JOIN departments d ON up.pathway_id = d.id
WHERE up.user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781';

-- Step 2: Assign the user to Vision pathway
INSERT INTO user_pathway (user_id, pathway_id, assigned_at)
SELECT 
  'fe3c162a-0b43-4a79-bdff-d32234429781',
  id,
  NOW()
FROM departments
WHERE title = 'Vision'
AND NOT EXISTS (
  SELECT 1 FROM user_pathway 
  WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781' 
  AND pathway_id = (SELECT id FROM departments WHERE title = 'Vision')
);

-- Step 3: Assign the user to Values pathway
INSERT INTO user_pathway (user_id, pathway_id, assigned_at)
SELECT 
  'fe3c162a-0b43-4a79-bdff-d32234429781',
  id,
  NOW()
FROM departments
WHERE title = 'Values'
AND NOT EXISTS (
  SELECT 1 FROM user_pathway 
  WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781' 
  AND pathway_id = (SELECT id FROM departments WHERE title = 'Values')
);

-- Step 4: Assign the user to Goals pathway
INSERT INTO user_pathway (user_id, pathway_id, assigned_at)
SELECT 
  'fe3c162a-0b43-4a79-bdff-d32234429781',
  id,
  NOW()
FROM departments
WHERE title = 'Goals'
AND NOT EXISTS (
  SELECT 1 FROM user_pathway 
  WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781' 
  AND pathway_id = (SELECT id FROM departments WHERE title = 'Goals')
);

-- Step 5: Verify assignments
SELECT 
  d.title as pathway_title,
  COUNT(DISTINCT dl.id) as num_levels,
  COUNT(DISTINCT q.id) as num_questions
FROM departments d
LEFT JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON dl.id = q.level_id
WHERE d.title IN ('Vision', 'Values', 'Goals')
GROUP BY d.title
ORDER BY d.title;

-- Expected result:
-- Goals: 1 level, 1 question
-- Values: 1 level, 1 question
-- Vision: 2 levels, 2 questions
