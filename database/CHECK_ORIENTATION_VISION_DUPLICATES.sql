-- Check Orientation-Vision for duplicate levels and question assignment

-- Step 1: Check for duplicate levels
SELECT 
  'DUPLICATE LEVELS IN ORIENTATION-VISION' as info,
  level_number,
  COUNT(*) as duplicate_count,
  array_agg(id::text) as level_ids,
  array_agg(title) as level_titles
FROM dept_levels
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
GROUP BY level_number
ORDER BY level_number;

-- Step 2: Check all levels and their question counts
SELECT 
  'ORIENTATION-VISION LEVELS' as info,
  dl.id,
  dl.title,
  dl.level_number,
  COUNT(q.id) as question_count
FROM dept_levels dl
LEFT JOIN questions q ON q.level_id = dl.id
WHERE dl.dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
GROUP BY dl.id, dl.title, dl.level_number
ORDER BY dl.level_number;

-- Step 3: Check where Vision questions are currently located
SELECT 
  'VISION QUESTIONS LOCATION' as info,
  q.id,
  q.title,
  q.description,
  q.level_id,
  dl.title as level_name,
  d.title as department
FROM questions q
JOIN dept_levels dl ON dl.id = q.level_id
JOIN departments d ON d.id = dl.dept_id
WHERE q.description LIKE '%Ease%' OR q.title LIKE '%Card Match%'
ORDER BY q.title;
