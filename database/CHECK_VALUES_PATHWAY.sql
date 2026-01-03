-- Check if Orientation - Values pathway has questions

-- 1. Find Orientation - Values department
SELECT 
  'ORIENTATION-VALUES DEPARTMENT' as info,
  id,
  title,
  description
FROM departments
WHERE title LIKE '%Values%'
ORDER BY title;

-- 2. Check levels for Orientation - Values
SELECT 
  'VALUES LEVELS' as info,
  d.title as department,
  dl.id as dept_levels_id,
  dl.level_number,
  dl.title as level_title,
  COUNT(q.id) as question_count
FROM departments d
LEFT JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.title LIKE '%Values%'
GROUP BY d.title, dl.id, dl.level_number, dl.title
ORDER BY d.title, dl.level_number;

-- 3. Show what questions exist for Values pathway
SELECT 
  'VALUES QUESTIONS' as info,
  d.title as department,
  dl.title as level_title,
  dl.level_number,
  q.title as question_title,
  q.description
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.title LIKE '%Values%'
ORDER BY d.title, dl.level_number;
