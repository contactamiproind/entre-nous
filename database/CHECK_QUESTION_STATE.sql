-- Check what the question's current level_id actually is

SELECT 
  'CURRENT QUESTION STATE' as info,
  id,
  title,
  level_id,
  dept_id,
  difficulty
FROM questions
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e838';
