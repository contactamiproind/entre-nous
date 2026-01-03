-- Verify pathway assignment was created
-- Run this in Supabase SQL Editor

SELECT 
  'user_pathway table' as check_type,
  up.id,
  up.user_id,
  up.pathway_id,
  up.pathway_name,
  up.is_current,
  up.assigned_by,
  up.assigned_at,
  p.email as user_email
FROM user_pathway up
JOIN profiles p ON p.user_id = up.user_id
WHERE p.email = 'naik.abhira@gmail.com';

SELECT 
  'user_progress table' as check_type,
  prog.id,
  prog.user_id,
  prog.pathway_id,
  prog.current_level,
  prog.current_score,
  p.email as user_email
FROM user_progress prog
JOIN profiles p ON p.user_id = prog.user_id
WHERE p.email = 'naik.abhira@gmail.com';
