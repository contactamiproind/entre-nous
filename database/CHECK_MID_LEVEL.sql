-- Check what the app should be querying for Mid level
-- Find the Mid level ID for Vision department

SELECT 
  'MID LEVEL INFO' as info,
  dl.id as dept_levels_id,
  dl.level_id,
  dl.level_number,
  dl.title,
  d.title as department,
  COUNT(q.id) as question_count
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.id = '0630caa4-3087-4192-a6b4-20053c74e8f3'  -- Vision department
  AND dl.level_number = 2
GROUP BY dl.id, dl.level_id, dl.level_number, dl.title, d.title;

-- Verify the Card Match question is assigned to this level
SELECT 
  'CARD MATCH QUESTION' as info,
  q.title,
  q.description,
  q.level_id,
  dl.id as dept_levels_id,
  dl.title as level_title
FROM questions q
LEFT JOIN dept_levels dl ON q.level_id = dl.id
WHERE q.description = 'Ease vs Delight';
