-- Fix: Allow NULL values in options column for Card Match questions
-- Card Match questions use options_data instead of options

ALTER TABLE questions 
ALTER COLUMN options DROP NOT NULL;

-- Verify the change
SELECT column_name, is_nullable, data_type
FROM information_schema.columns
WHERE table_name = 'questions' AND column_name = 'options';
