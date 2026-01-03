-- Check the actual structure of dept_levels table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'dept_levels'
ORDER BY ordinal_position;
