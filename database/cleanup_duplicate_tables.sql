-- Clean up duplicate tables - Remove 'questions' table and keep only 'question_bank'

-- Step 1: Drop the 'questions' table if it exists
DROP TABLE IF EXISTS questions CASCADE;

-- Step 2: Verify question_bank exists and has the correct structure
-- This is just a verification query - run it to check
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'question_bank'
ORDER BY ordinal_position;
