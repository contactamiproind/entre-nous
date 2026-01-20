-- Check all NOT NULL constraints on questions table
SELECT 
    column_name, 
    is_nullable, 
    data_type,
    column_default
FROM information_schema.columns
WHERE table_name = 'questions'
ORDER BY ordinal_position;
