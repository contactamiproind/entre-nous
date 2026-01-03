-- First, let's check what foreign key constraints exist on the questions table
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
  AND tc.constraint_type = 'FOREIGN KEY';

-- Check if there's a 'levels' table
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE '%level%';

-- Check what's in the levels table (if it exists)
SELECT * FROM levels ORDER BY created_at LIMIT 10;

-- Check the dept_levels table structure
SELECT id, level_id, title, level_number, dept_id
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY level_number;
