-- Check if the UPDATE actually worked

SELECT 
  'QUESTION CURRENT STATE' as info,
  id,
  title,
  level_id,
  dept_id
FROM questions
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e839';

-- Also check how many questions exist total
SELECT 
  'TOTAL QUESTIONS' as info,
  COUNT(*) as total_count
FROM questions;
