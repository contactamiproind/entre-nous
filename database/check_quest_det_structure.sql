-- Check the structure of quest_det table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'quest_det'
ORDER BY ordinal_position;
