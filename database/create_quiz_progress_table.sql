-- Create quiz_progress table for tracking quiz attempts
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS quiz_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  level INTEGER NOT NULL,
  score INTEGER NOT NULL,
  total_questions INTEGER NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE quiz_progress ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own quiz progress
CREATE POLICY "Users can view own quiz progress"
ON quiz_progress FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Allow users to insert their own quiz progress
CREATE POLICY "Users can insert own quiz progress"
ON quiz_progress FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_quiz_progress_user ON quiz_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_progress_level ON quiz_progress(level);
