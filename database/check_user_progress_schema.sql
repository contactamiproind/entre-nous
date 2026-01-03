-- Check actual user_progress table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_progress'
ORDER BY ordinal_position;

-- Also check what records currently exist
SELECT * FROM user_progress LIMIT 5;
