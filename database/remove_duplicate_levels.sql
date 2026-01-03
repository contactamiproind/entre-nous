-- Remove duplicate levels, keeping the one with the smallest ID
DELETE FROM dept_levels a USING dept_levels b
WHERE a.id > b.id
  AND a.dept_id = b.dept_id
  AND a.level_number = b.level_number;

-- Add a unique constraint to prevent future duplicates if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'dept_levels_dept_id_level_number_key'
    ) THEN
        ALTER TABLE dept_levels 
        ADD CONSTRAINT dept_levels_dept_id_level_number_key 
        UNIQUE (dept_id, level_number);
    END IF;
END $$;
