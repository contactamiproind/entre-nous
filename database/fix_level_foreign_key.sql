-- Check which level table has data and fix the foreign key reference

-- Step 1: Check if you have data in 'levels' table
SELECT 'levels table' as table_name, COUNT(*) as count FROM levels;

-- Step 2: Check if you have data in 'pathway_levels' table  
SELECT 'pathway_levels table' as table_name, COUNT(*) as count FROM pathway_levels;

-- Step 3: If pathway_levels has data and levels is empty, we need to update the foreign key
-- Run this ONLY if pathway_levels has your data:

-- Drop the old foreign key constraint
ALTER TABLE question_bank 
DROP CONSTRAINT IF EXISTS question_bank_level_id_fkey;

-- Add new foreign key pointing to pathway_levels
ALTER TABLE question_bank
ADD CONSTRAINT question_bank_level_id_fkey 
FOREIGN KEY (level_id) 
REFERENCES pathway_levels(id) 
ON DELETE CASCADE;

-- Verify the change
SELECT 
  tc.constraint_name, 
  tc.table_name, 
  kcu.column_name, 
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'question_bank' 
  AND tc.constraint_type = 'FOREIGN KEY';
