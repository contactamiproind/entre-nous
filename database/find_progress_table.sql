-- Check for other progress-related tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE '%progress%' OR table_name LIKE '%user%'
ORDER BY table_name;

-- Check user_progress table if it exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'user_progress' 
ORDER BY ordinal_position;

-- Check if there's data in user_progress
SELECT * FROM user_progress 
WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781'
LIMIT 5;
