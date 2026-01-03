-- Check if the question was actually updated

SELECT 
  'CURRENT STATE' as info,
  id,
  title,
  level_id,
  dept_id
FROM questions
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e039';
