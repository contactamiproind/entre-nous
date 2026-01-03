-- Find the actual Card Match question ID

SELECT 
  'FIND CARD MATCH' as info,
  id,
  title,
  description,
  level_id,
  question_type
FROM questions
WHERE title LIKE '%Card Match%' OR question_type = 'card_match'
ORDER BY title;

-- Also check by description
SELECT 
  'FIND BY TYPE' as info,
  id,
  title,
  question_type,
  level_id
FROM questions
WHERE question_type = 'card_match';
