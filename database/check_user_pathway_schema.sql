-- Check user_pathway table schema
-- Run this in Supabase SQL Editor

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'user_pathway'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show sample data
SELECT * FROM user_pathway LIMIT 3;
