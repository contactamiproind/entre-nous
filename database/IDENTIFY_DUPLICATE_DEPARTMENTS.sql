-- Identify duplicate departments and create cleanup plan

-- 1. Find all standalone departments that have "Orientation - [name]" equivalents
SELECT 
  'DUPLICATE DEPARTMENTS' as info,
  d1.id as standalone_id,
  d1.title as standalone_title,
  d2.id as orientation_version_id,
  d2.title as orientation_version_title
FROM departments d1
JOIN departments d2 ON d2.title = 'Orientation - ' || d1.title
WHERE d1.title NOT LIKE 'Orientation%'
ORDER BY d1.title;

-- 2. Check if standalone departments have any questions
SELECT 
  'QUESTIONS IN STANDALONE DEPTS' as info,
  d.title as department,
  COUNT(q.id) as question_count
FROM departments d
LEFT JOIN dept_levels dl ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.title IN ('Vision', 'Goals', 'Values')
  AND d.title NOT LIKE 'Orientation%'
GROUP BY d.id, d.title
ORDER BY d.title;

-- 3. Check if standalone departments have any user assignments
SELECT 
  'USER ASSIGNMENTS IN STANDALONE DEPTS' as info,
  d.title as department,
  COUNT(up.user_id) as user_count
FROM departments d
LEFT JOIN user_pathway up ON up.pathway_id = d.id
WHERE d.title IN ('Vision', 'Goals', 'Values')
  AND d.title NOT LIKE 'Orientation%'
GROUP BY d.id, d.title
ORDER BY d.title;
