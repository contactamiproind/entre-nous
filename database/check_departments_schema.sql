-- First, check the actual structure of the departments table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'departments' 
ORDER BY ordinal_position;

-- Check existing departments
SELECT * FROM departments LIMIT 5;
