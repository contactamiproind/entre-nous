-- First, let's check the actual structure of quest_types table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'quest_types' 
AND table_schema = 'public';

-- Also check existing constraints
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'quest_types'::regclass;
