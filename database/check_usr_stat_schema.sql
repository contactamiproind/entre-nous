-- Check the actual structure of usr_stat table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'usr_stat' 
ORDER BY ordinal_position;

-- Check existing data in usr_stat
SELECT * FROM usr_stat 
WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781'
LIMIT 5;
