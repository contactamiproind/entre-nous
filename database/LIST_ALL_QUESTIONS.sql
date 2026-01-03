-- List ALL questions to find the correct Values question

SELECT 
  id,
  title,
  description,
  level_id,
  dept_id
FROM questions
ORDER BY title;
