-- Deploy question_options table to Supabase
-- Run this script in Supabase SQL Editor

-- Create question_options table
CREATE TABLE IF NOT EXISTS question_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    sub_question_number INTEGER DEFAULT 1,
    option_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    match_pair_left TEXT,
    match_pair_right TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE question_options IS 'Answer options for questions (MCQ options, match pairs, etc.)';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_question_options_question_id ON question_options(question_id);
CREATE INDEX IF NOT EXISTS idx_question_options_sub_question ON question_options(question_id, sub_question_number);

-- Enable RLS
ALTER TABLE question_options ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Anyone can view question options" ON question_options;
CREATE POLICY "Anyone can view question options" ON question_options
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage question options" ON question_options;
CREATE POLICY "Admins can manage question options" ON question_options
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.user_id = auth.uid()
            AND profiles.role = 'admin'
        )
    );
