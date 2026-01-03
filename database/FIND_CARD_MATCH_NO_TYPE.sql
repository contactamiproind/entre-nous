-- Find Card Match question without using question_type column

SELECT 
  'ALL QUESTIONS' as info,
  id,
  title,
  description,
  level_id
FROM questions
WHERE title LIKE '%Card%' OR title LIKE '%Match%' OR description LIKE '%match%'
ORDER BY title;

-- Also just list all questions to find it
SELECT 
  'ALL QUESTIONS FOR VISION' as info,
  q.id,
  q.title,
  q.level_id,
  dl.level_number,
  d.title as department
FROM questions q
LEFT JOIN dept_levels dl ON dl.id = q.level_id
LEFT JOIN departments d ON d.id = dl.dept_id
WHERE d.title LIKE '%Vision%'
ORDER BY q.title;
