-- Check which pathways have questions and which user is assigned

-- Step 1: Check the user's assigned pathway
SELECT 
  u.email,
  up.pathway_id,
  d.title as pathway_name,
  up.is_current,
  prog.current_level
FROM auth.users u
JOIN user_pathway up ON u.id = up.user_id
JOIN departments d ON up.pathway_id = d.id
LEFT JOIN user_progress prog ON u.id = prog.user_id
WHERE u.email = 'contactamiproind@gmail.com'
ORDER BY up.assigned_at DESC;

-- Step 2: Check if that pathway has questions
SELECT 
  d.title as pathway_name,
  pl.level_number,
  pl.level_name,
  COUNT(q.id) as question_count
FROM departments d
LEFT JOIN pathway_levels pl ON d.id = pl.pathway_id
LEFT JOIN questions q ON pl.id = q.level_id
WHERE d.title = 'Vision'  -- Replace with actual pathway name from Step 1
GROUP BY d.title, pl.level_number, pl.level_name
ORDER BY pl.level_number;

-- Step 3: Check all pathways with question counts
SELECT 
  d.title as pathway_name,
  COUNT(DISTINCT pl.id) as total_levels,
  COUNT(q.id) as total_questions
FROM departments d
LEFT JOIN pathway_levels pl ON d.id = pl.pathway_id
LEFT JOIN questions q ON pl.id = q.level_id
GROUP BY d.title
ORDER BY total_questions DESC;

-- Step 4: If no questions, check if pathway_levels exist
SELECT 
  d.title as pathway_name,
  pl.id as level_id,
  pl.level_number,
  pl.level_name
FROM departments d
LEFT JOIN pathway_levels pl ON d.id = pl.pathway_id
WHERE d.title = 'Vision'  -- Replace with actual pathway name
ORDER BY pl.level_number;
