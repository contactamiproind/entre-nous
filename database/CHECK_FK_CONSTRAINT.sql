-- Check the actual foreign key constraint on questions table
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'questions' 
  AND tc.constraint_type = 'FOREIGN KEY'
  AND kcu.column_name = 'level_id';

-- Check what the dept_levels table actually contains
SELECT 
  'DEPT_LEVELS STRUCTURE' as info,
  id,
  level_id,
  dept_id,
  level_number,
  title
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY level_number;
