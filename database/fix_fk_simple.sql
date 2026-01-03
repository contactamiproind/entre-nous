-- Fix question_bank foreign key to point to pathway_levels
-- Run this in Supabase SQL Editor

-- Step 1: Drop the existing foreign key constraint
ALTER TABLE question_bank 
DROP CONSTRAINT question_bank_level_id_fkey;

-- Step 2: Add new foreign key pointing to pathway_levels
ALTER TABLE question_bank
ADD CONSTRAINT question_bank_level_id_fkey 
FOREIGN KEY (level_id) 
REFERENCES pathway_levels(id) 
ON DELETE CASCADE;

-- Step 3: Verify the change
SELECT 
  tc.constraint_name, 
  tc.table_name, 
  kcu.column_name, 
  ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'question_bank' 
  AND tc.constraint_type = 'FOREIGN KEY'
  AND kcu.column_name = 'level_id';
