-- Show the exact level_id values for questions and dept_levels

SELECT 
  'QUESTIONS' as source,
  q.title,
  q.description,
  q.level_id,
  q.dept_id
FROM questions q
WHERE q.description IN ('Which action best creates Ease for a client?', 'Ease vs Delight')
ORDER BY q.description;

SELECT 
  'DEPT_LEVELS' as source,
  dl.id as dept_levels_id,
  dl.level_number,
  dl.title as level_title,
  d.title as department
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number;
