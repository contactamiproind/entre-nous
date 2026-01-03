-- Add question_type and match_pairs columns to question_bank table

-- Step 1: Add question_type column (default to 'multiple_choice' for existing questions)
ALTER TABLE question_bank 
ADD COLUMN IF NOT EXISTS question_type TEXT DEFAULT 'multiple_choice';

-- Step 2: Add match_pairs column for storing match-the-following pairs
ALTER TABLE question_bank 
ADD COLUMN IF NOT EXISTS match_pairs JSONB;

-- Step 3: Update existing questions to explicitly set question_type
UPDATE question_bank 
SET question_type = 'multiple_choice' 
WHERE question_type IS NULL;

-- Step 4: Add comment for documentation
COMMENT ON COLUMN question_bank.question_type IS 'Type of question: multiple_choice or match_following';
COMMENT ON COLUMN question_bank.match_pairs IS 'For match_following questions: array of {left, right} pairs in JSON format';

-- Note: The constraint 'valid_question_type' already exists in your schema, so we skip adding it

