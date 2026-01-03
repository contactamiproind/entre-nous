-- Clean up user_pathway table
-- Run this in Supabase SQL Editor

-- Remove redundant columns
ALTER TABLE user_pathway
DROP COLUMN IF EXISTS completed;

ALTER TABLE user_pathway
DROP COLUMN IF EXISTS completed_at;

-- Verify remaining columns
SELECT 
  'Remaining columns in user_pathway' as info;

SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'user_pathway'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Expected columns:
SELECT 'Expected columns:' as info;
SELECT 'id, user_id, pathway_id, pathway_name, is_current, assigned_by, assigned_at, last_accessed_at, enrolled_at' as should_remain;
