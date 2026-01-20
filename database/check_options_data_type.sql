-- Check the data type of options_data column
SELECT 
    column_name, 
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'questions' 
  AND column_name IN ('options', 'options_data');
