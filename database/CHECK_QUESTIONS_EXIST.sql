-- Check if questions table has any data at all

SELECT 
  'TOTAL QUESTIONS' as info,
  COUNT(*) as total_count
FROM questions;

-- List ALL questions
SELECT 
  'ALL QUESTIONS' as info,
  id,
  title,
  level_id,
  dept_id
FROM questions
ORDER BY title
LIMIT 20;

-- Check specifically for Vision-related questions
SELECT 
  'VISION QUESTIONS' as info,
  q.id,
  q.title,
  q.level_id,
  q.dept_id
FROM questions q
WHERE q.title LIKE '%Single%' OR q.title LIKE '%Card%' OR q.title LIKE '%Tap%' OR q.title LIKE '%Match%';
