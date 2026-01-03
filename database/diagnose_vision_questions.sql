-- Comprehensive diagnostic for Vision pathway questions issue

-- Step 1: Verify user's current pathway assignment
SELECT 
  'User Assignment' as check_type,
  u.email,
  d.title as assigned_pathway,
  up.is_current,
  prog.current_level,
  prog.current_pathway_id
FROM auth.users u
JOIN user_pathway up ON u.id = up.user_id
JOIN departments d ON up.pathway_id = d.id
LEFT JOIN user_progress prog ON u.id = prog.user_id
WHERE u.email = 'contactamiproind@gmail.com';

-- Step 2: Check Vision pathway levels
SELECT 
  'Vision Levels' as check_type,
  pl.id as level_id,
  pl.pathway_id,
  pl.level_number,
  pl.level_name,
  pl.difficulty
FROM pathway_levels pl
JOIN departments d ON pl.pathway_id = d.id
WHERE d.title = 'Vision'
ORDER BY pl.level_number;

-- Step 3: Check questions for Vision pathway
SELECT 
  'Vision Questions' as check_type,
  pl.level_number,
  pl.level_name,
  q.id as question_id,
  q.question_text,
  q.level_id
FROM departments d
JOIN pathway_levels pl ON d.id = pl.pathway_id
LEFT JOIN questions q ON pl.id = q.level_id
WHERE d.title = 'Vision'
ORDER BY pl.level_number, q.id
LIMIT 20;

-- Step 4: Check if questions have correct level_id
SELECT 
  'Question Level Mapping' as check_type,
  q.id as question_id,
  q.level_id,
  q.question_text,
  pl.level_name,
  d.title as pathway_name
FROM questions q
LEFT JOIN pathway_levels pl ON q.level_id = pl.id
LEFT JOIN departments d ON pl.pathway_id = d.id
WHERE d.title = 'Vision'
LIMIT 10;

-- Step 5: Check user's current level details
SELECT 
  'User Current Level' as check_type,
  prog.current_level as level_number,
  pl.id as level_id,
  pl.level_name,
  COUNT(q.id) as questions_at_this_level
FROM user_progress prog
JOIN auth.users u ON prog.user_id = u.id
JOIN departments d ON prog.current_pathway_id = d.id
LEFT JOIN pathway_levels pl ON d.id = pl.pathway_id AND pl.level_number = prog.current_level
LEFT JOIN questions q ON pl.id = q.level_id
WHERE u.email = 'contactamiproind@gmail.com'
GROUP BY prog.current_level, pl.id, pl.level_name;
