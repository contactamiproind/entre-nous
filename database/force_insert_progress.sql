-- Direct insert bypassing RLS
-- Run this in Supabase SQL Editor

-- First, check what we have
SELECT 'Current user_pathway records' as info;
SELECT up.*, p.email
FROM user_pathway up
JOIN profiles p ON p.user_id = up.user_id
WHERE p.email = 'naik.abhira@gmail.com';

SELECT 'Current user_progress records' as info;
SELECT prog.*, p.email
FROM user_progress prog
JOIN profiles p ON p.user_id = prog.user_id
WHERE p.email = 'naik.abhira@gmail.com';

-- Now insert directly with specific IDs
INSERT INTO user_progress (user_id, pathway_id, current_level, current_score)
VALUES (
  (SELECT user_id FROM profiles WHERE email = 'naik.abhira@gmail.com'),
  (SELECT pathway_id FROM user_pathway WHERE user_id = (SELECT user_id FROM profiles WHERE email = 'naik.abhira@gmail.com')),
  1,
  0
)
ON CONFLICT (user_id, pathway_id) DO UPDATE
SET current_level = 1, current_score = 0;

-- Final verification
SELECT 'FINAL CHECK - Both tables should have records' as info;

SELECT 'user_pathway' as table_name, COUNT(*) as record_count
FROM user_pathway up
JOIN profiles p ON p.user_id = up.user_id
WHERE p.email = 'naik.abhira@gmail.com';

SELECT 'user_progress' as table_name, COUNT(*) as record_count
FROM user_progress prog
JOIN profiles p ON p.user_id = prog.user_id
WHERE p.email = 'naik.abhira@gmail.com';
