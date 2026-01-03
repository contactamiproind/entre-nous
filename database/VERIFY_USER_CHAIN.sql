-- Verify the complete chain: user → department → levels → questions

-- 1. Check which department the user is assigned to
SELECT 
  'USER ASSIGNMENT' as info,
  u.email,
  d.id as dept_id,
  d.title as department,
  up.current_level
FROM user_pathway upw
JOIN auth.users u ON u.id = upw.user_id
JOIN departments d ON d.id = upw.pathway_id
JOIN user_progress up ON up.user_id = u.id
WHERE u.email = 'contactamiproind@gmail.com'
  AND upw.is_current = true;

-- 2. Check the levels for that department
SELECT 
  'DEPARTMENT LEVELS' as info,
  dl.id as level_id,
  dl.title,
  dl.level_number,
  dl.dept_id
FROM dept_levels dl
WHERE dl.dept_id = (
  SELECT upw.pathway_id 
  FROM user_pathway upw
  JOIN auth.users u ON u.id = upw.user_id
  WHERE u.email = 'contactamiproind@gmail.com' AND upw.is_current = true
)
ORDER BY dl.level_number;

-- 3. Check questions for those levels
SELECT 
  'QUESTIONS FOR USER DEPARTMENT' as info,
  q.id,
  q.title,
  q.level_id,
  dl.level_number
FROM questions q
JOIN dept_levels dl ON dl.id = q.level_id
WHERE dl.dept_id = (
  SELECT upw.pathway_id 
  FROM user_pathway upw
  JOIN auth.users u ON u.id = upw.user_id
  WHERE u.email = 'contactamiproind@gmail.com' AND upw.is_current = true
)
ORDER BY dl.level_number, q.title;
