-- Check the actual schema of dept_levels table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'dept_levels'
ORDER BY ordinal_position;
