-- Complete diagnostic: Check the entire flow from user to questions
-- 1. Check user pathway assignment
SELECT 
  'USER PATHWAY ASSIGNMENT' as check_type,
  up.user_id,
  u.email,
  d.id as pathway_id,
  d.title as pathway_name,
  up.is_current
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
WHERE d.title = 'Orientation - Vision';

-- 2. Check dept_levels for this pathway
SELECT 
  'DEPT LEVELS' as check_type,
  dl.id as level_id,
  dl.dept_id,
  dl.level_number,
  dl.title as level_title,
  d.title as department
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.title = 'Orientation - Vision'
ORDER BY dl.level_number;

-- 3. Check questions linked to these levels
SELECT 
  'QUESTIONS' as check_type,
  q.id as question_id,
  q.title as question_title,
  q.description,
  q.dept_id,
  q.level_id,
  dl.title as level_title,
  dl.level_number
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
JOIN departments d ON dl.dept_id = d.id
WHERE d.title = 'Orientation - Vision'
ORDER BY dl.level_number;

-- 4. Check if there are any orphaned questions (dept_id set but level_id wrong)
SELECT 
  'ORPHANED QUESTIONS' as check_type,
  q.id,
  q.title,
  q.description,
  q.dept_id,
  q.level_id,
  d.title as department
FROM questions q
JOIN departments d ON q.dept_id = d.id
LEFT JOIN dept_levels dl ON q.level_id = dl.id
WHERE d.title = 'Orientation - Vision'
  AND dl.id IS NULL;
