-- Check questions for abhira123@gmail.com's assigned pathway

-- Step 1: Get user's assigned pathway
SELECT 
  u.email,
  d.id as pathway_id,
  d.title as pathway_name
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
WHERE u.email = 'abhira123@gmail.com';

-- Step 2: Get levels for this pathway
SELECT 
  dl.id as level_id,
  dl.level_id as level_uuid,
  dl.level_number,
  dl.title as level_name,
  d.title as pathway_name
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.title IN (
  SELECT d.title 
  FROM user_pathway up
  JOIN auth.users u ON up.user_id = u.id
  JOIN departments d ON up.pathway_id = d.id
  WHERE u.email = 'abhira123@gmail.com'
)
ORDER BY dl.level_number;

-- Step 3: Check questions linked to these levels
SELECT 
  d.title as pathway_name,
  dl.level_number,
  dl.title as level_name,
  COUNT(q.id) as question_count,
  STRING_AGG(q.title, ', ') as question_titles
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.title IN (
  SELECT d.title 
  FROM user_pathway up
  JOIN auth.users u ON up.user_id = u.id
  JOIN departments d ON up.pathway_id = d.id
  WHERE u.email = 'abhira123@gmail.com'
)
GROUP BY d.title, dl.level_number, dl.title
ORDER BY d.title, dl.level_number;
