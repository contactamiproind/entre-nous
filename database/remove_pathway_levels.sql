-- Remove duplicate pathway_levels table
-- We only need the 'levels' table which has pathway_id

-- Step 1: Drop the pathway_levels table
DROP TABLE IF EXISTS pathway_levels CASCADE;

-- Verification: List all tables to confirm
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
