-- Check the actual schema of usr_stat table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'usr_stat'
ORDER BY ordinal_position;

-- View all data for this user
SELECT *
FROM usr_stat
WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781';

-- Delete all records for this user (force fresh reload)
DELETE FROM usr_stat
WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781';

-- Verify deletion
SELECT COUNT(*) as remaining_records
FROM usr_stat
WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781';
