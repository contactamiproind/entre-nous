-- Check if questions exist and what level_id they're using
SELECT COUNT(*) as total_questions FROM questions;

-- Check what level_id the "Easy" level has in dept_levels
SELECT id, level_id, title, level_number, dept_id
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
  AND level_number = 1;

-- Check if any questions are linked to the dept_levels.id (not level_id)
SELECT q.id, q.title, q.level_id, dl.title as level_title, dl.level_number
FROM questions q
LEFT JOIN dept_levels dl ON q.level_id = dl.id
WHERE dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number;

-- Check if any questions are linked to the dept_levels.level_id field
SELECT q.id, q.title, q.level_id, dl.title as level_title, dl.level_number
FROM questions q
LEFT JOIN dept_levels dl ON q.level_id = dl.level_id
WHERE dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number;
