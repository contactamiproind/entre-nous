-- Analyze current database structure for pathways

-- 1. Check all departments (pathways)
SELECT 
  'ALL DEPARTMENTS' as info,
  id,
  title,
  description,
  created_at
FROM departments
ORDER BY title;

-- 2. Check all dept_levels for each department
SELECT 
  'ALL DEPT_LEVELS' as info,
  d.title as department,
  dl.id as level_id,
  dl.level_number,
  dl.title as level_title,
  dl.category,
  COUNT(q.id) as question_count
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
GROUP BY d.title, dl.id, dl.level_number, dl.title, dl.category
ORDER BY d.title, dl.level_number;

-- 3. Check all questions and their assignments
SELECT 
  'ALL QUESTIONS' as info,
  q.id,
  q.title,
  q.description,
  d.title as department,
  dl.title as level_title,
  dl.level_number
FROM questions q
LEFT JOIN dept_levels dl ON q.level_id = dl.id
LEFT JOIN departments d ON dl.dept_id = d.id
ORDER BY d.title, dl.level_number, q.title;

-- 4. Check user pathway assignments
SELECT 
  'USER ASSIGNMENTS' as info,
  u.email,
  d.title as assigned_pathway,
  up.is_current
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
ORDER BY u.email, d.title;
