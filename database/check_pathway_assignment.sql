-- Check if pathway assignment exists for the user
-- Run this in Supabase SQL Editor

-- Check user_pathway table
SELECT 
  'user_pathway records' as table_name,
  up.id,
  up.user_id,
  up.pathway_id,
  up.pathway_name,
  up.is_current,
  up.assigned_by,
  up.assigned_at,
  up.enrolled_at,
  p.email as user_email
FROM user_pathway up
JOIN profiles p ON p.user_id = up.user_id
WHERE p.email = 'naik.abhira@gmail.com';

-- Check user_progress table
SELECT 
  'user_progress records' as table_name,
  prog.id,
  prog.user_id,
  prog.pathway_id,
  prog.current_level,
  prog.current_score,
  p.email as user_email
FROM user_progress prog
JOIN profiles p ON p.user_id = prog.user_id
WHERE p.email = 'naik.abhira@gmail.com';

-- If no records found, the assignment didn't save
-- Check for any errors or constraints
SELECT 
  'Checking constraints' as step;
