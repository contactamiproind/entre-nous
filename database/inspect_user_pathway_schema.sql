-- First, let's see what columns exist in user_pathway table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_pathway'
ORDER BY ordinal_position;

-- Then let's see the actual data
SELECT *
FROM user_pathway
LIMIT 5;
