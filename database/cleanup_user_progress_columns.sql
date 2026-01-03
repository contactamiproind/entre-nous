-- Clean up redundant columns from user_progress table
-- Run this in Supabase SQL Editor

-- IMPORTANT: This will permanently delete these columns and their data
-- Make sure you have a backup if needed

-- Step 1: Remove redundant columns
-- Remove total_marks (redundant with current_score)
ALTER TABLE user_progress
DROP COLUMN IF EXISTS total_marks;

-- Remove level_id (redundant, we use current_level number)
ALTER TABLE user_progress
DROP COLUMN IF EXISTS level_id;

-- Step 2: Verify the cleanup
SELECT 
  'Remaining columns in user_progress' as info;

SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'user_progress'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 3: Show what we kept
SELECT 'Expected columns:' as info;
SELECT 'id, user_id, pathway_id, current_level, current_score, created_at, updated_at' as should_remain;
