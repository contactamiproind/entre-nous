-- Check current question level_ids vs correct Orientation level_ids
SELECT 'Current Questions' as source, id, title, level_id
FROM questions
WHERE level_id IS NOT NULL
ORDER BY created_at

UNION ALL

SELECT 'Orientation Levels' as source, level_id as id, title, level_id
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY source, level_number;
