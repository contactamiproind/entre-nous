-- Check if there are questions for the Orientation pathway levels
SELECT 
  q.id,
  q.category,
  q.subcategory,
  q.title,
  dl.level_number,
  dl.title as level_title
FROM questions q
LEFT JOIN dept_levels dl ON q.level_id = dl.level_id
WHERE dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number, q.created_at;

-- Also check if questions exist without level_id
SELECT COUNT(*) as total_questions FROM questions;
SELECT COUNT(*) as questions_with_null_category FROM questions WHERE category IS NULL;
SELECT COUNT(*) as questions_with_level_id FROM questions WHERE level_id IS NOT NULL;
