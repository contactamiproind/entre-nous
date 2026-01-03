-- Check where the Orientation-Values questions actually are

-- 1. Find the Orientation-Values department ID
SELECT 
  'ORIENTATION-VALUES DEPT' as info,
  id,
  title
FROM departments
WHERE title LIKE '%Values%'
ORDER BY title;

-- 2. Check dept_levels for Orientation-Values
SELECT 
  'VALUES DEPT_LEVELS' as info,
  d.title as department,
  dl.id as dept_level_id,
  dl.level_number,
  dl.title as level_title
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
WHERE d.title LIKE '%Values%'
ORDER BY dl.level_number;

-- 3. Check if questions are assigned to these dept_levels
SELECT 
  'QUESTIONS IN VALUES' as info,
  d.title as department,
  dl.title as level_title,
  dl.id as dept_level_id,
  q.title as question_title,
  q.level_id as question_level_id
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.title LIKE '%Values%'
ORDER BY dl.level_number;

-- 4. Find the "Single Tap Choice" Values question
SELECT 
  'SINGLE TAP CHOICE QUESTION' as info,
  q.id,
  q.title,
  q.description,
  q.level_id,
  q.dept_id,
  d.title as department
FROM questions q
LEFT JOIN departments d ON q.dept_id = d.id
WHERE q.title = 'Single Tap Choice'
  AND q.description LIKE '%value%';
