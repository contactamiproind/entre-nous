-- Add options column to questions table
-- Run this script in Supabase SQL Editor

-- Add options column to store answer options as JSONB array
ALTER TABLE questions 
ADD COLUMN IF NOT EXISTS options JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN questions.options IS 'Answer options for the question stored as JSON array';

-- Example of how options will be stored:
-- For multiple choice: [{"text": "Option A", "is_correct": true}, {"text": "Option B", "is_correct": false}]
-- For match the following: [{"left": "Item 1", "right": "Match 1"}, {"left": "Item 2", "right": "Match 2"}]
