-- Check complete flow: user assignment → department → levels → questions

-- 1. Check a specific user's assignment
SELECT 
  'USER ASSIGNMENT' as info,
  u.email,
  up.user_id,
  up.current_level,
  d.title as assigned_department,
  d.id as dept_id
FROM user_progress up
JOIN auth.users u ON u.id = up.user_id
JOIN user_pathway upw ON upw.user_id = up.user_id AND upw.is_current = true
JOIN departments d ON d.id = upw.pathway_id
WHERE u.email = 'contactamiproind@gmail.com';

-- 2. Check what levels exist for that department
SELECT 
  'DEPARTMENT LEVELS' as info,
  dl.id as level_id,
  dl.title,
  dl.level_number,
  d.title as department
FROM dept_levels dl
JOIN departments d ON d.id = dl.dept_id
WHERE d.title = 'Orientation - Vision'
ORDER BY dl.level_number;

-- 3. Check what questions are assigned to those levels
SELECT 
  'QUESTIONS FOR LEVELS' as info,
  q.id as question_id,
  q.title as question_title,
  q.level_id,
  dl.title as level_name,
  dl.level_number
FROM questions q
JOIN dept_levels dl ON dl.id = q.level_id
JOIN departments d ON d.id = dl.dept_id
WHERE d.title = 'Orientation - Vision'
ORDER BY dl.level_number, q.title;

-- 4. Check what the app will query (simulate app's query)
SELECT 
  'APP QUERY SIMULATION' as info,
  q.*
FROM questions q
WHERE q.level_id IN (
  SELECT id FROM dept_levels 
  WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
    AND level_number = 1
);
