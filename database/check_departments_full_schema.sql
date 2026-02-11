-- Check the actual schema of the departments table
SELECT 
    column_name, 
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'departments'
ORDER BY ordinal_position;
