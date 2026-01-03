-- Add missing columns to questions table for storing question options and correct answer
ALTER TABLE questions
ADD COLUMN IF NOT EXISTS options jsonb,
ADD COLUMN IF NOT EXISTS correct_answer text;

-- Add comment to explain the columns
COMMENT ON COLUMN questions.options IS 'Array of answer options for multiple choice questions';
COMMENT ON COLUMN questions.correct_answer IS 'The correct answer (A, B, C, D for multiple choice)';
