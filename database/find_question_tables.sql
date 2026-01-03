-- Check all tables that might store question data
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE '%quest%'
ORDER BY table_name;

-- Also check for any table with 'option' or 'answer' in the name
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND (table_name LIKE '%option%' OR table_name LIKE '%answer%')
ORDER BY table_name;
