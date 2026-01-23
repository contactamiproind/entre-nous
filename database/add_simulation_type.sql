-- Add simulation question type to quest_types table

-- First, check if it already exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM quest_types WHERE type = 'simulation') THEN
        INSERT INTO quest_types (type, description)
        VALUES ('simulation', 'Budget Allocation Simulation Game');
        
        RAISE NOTICE 'Added simulation type to quest_types';
    ELSE
        RAISE NOTICE 'Simulation type already exists';
    END IF;
END $$;

-- Verify the insertion
SELECT * FROM quest_types WHERE type = 'simulation';
