-- Add missing user_progress record
-- Run this in Supabase SQL Editor

-- Insert user_progress for the assigned pathway
INSERT INTO user_progress (user_id, pathway_id, current_level, current_score)
SELECT 
  up.user_id,
  up.pathway_id,
  1,
  0
FROM user_pathway up
JOIN profiles p ON p.user_id = up.user_id
WHERE p.email = 'naik.abhira@gmail.com'
AND NOT EXISTS (
  SELECT 1 FROM user_progress prog
  WHERE prog.user_id = up.user_id
  AND prog.pathway_id = up.pathway_id
);

-- Verify both records now exist
SELECT 
  'VERIFICATION - user_pathway' as table_name,
  up.pathway_name,
  up.is_current,
  p.email
FROM user_pathway up
JOIN profiles p ON p.user_id = up.user_id
WHERE p.email = 'naik.abhira@gmail.com';

SELECT 
  'VERIFICATION - user_progress' as table_name,
  prog.current_level,
  prog.current_score,
  p.email
FROM user_progress prog
JOIN profiles p ON p.user_id = prog.user_id
WHERE p.email = 'naik.abhira@gmail.com';
