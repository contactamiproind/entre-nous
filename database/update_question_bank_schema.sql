-- Update question_bank table
-- Run this in Supabase SQL Editor

-- Step 1: Rename 'points' to 'currency' and change to DECIMAL
ALTER TABLE question_bank
RENAME COLUMN points TO currency;

-- Change data type to DECIMAL to accept decimal values (e.g., 10.5, 25.75)
ALTER TABLE question_bank
ALTER COLUMN currency TYPE DECIMAL(10, 2);

-- Step 2: Add 'created_by' column (admin who created the question)
ALTER TABLE question_bank
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(user_id);

-- Step 3: Add 'updated_by' column (admin who last updated the question)
ALTER TABLE question_bank
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES profiles(user_id);

-- Step 4: Set default values for existing records
-- Set created_by to first admin for existing questions
UPDATE question_bank
SET created_by = (
  SELECT user_id FROM profiles WHERE role = 'admin' LIMIT 1
)
WHERE created_by IS NULL;

-- Set updated_by same as created_by for existing questions
UPDATE question_bank
SET updated_by = created_by
WHERE updated_by IS NULL;

-- Step 5: Verify the changes
SELECT 
  'question_bank schema' as info;

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'question_bank'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show sample data
SELECT 
  'Sample question_bank data' as info;
  
SELECT 
  id,
  currency,
  created_by,
  updated_by,
  created_at
FROM question_bank
LIMIT 5;
