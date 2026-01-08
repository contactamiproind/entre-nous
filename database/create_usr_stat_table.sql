-- ============================================
-- CREATE MISSING usr_stat TABLE
-- Run this in Supabase SQL Editor
-- ============================================

-- This table is needed to track quiz answer statistics
-- The app is trying to insert into this table but it doesn't exist

CREATE TABLE IF NOT EXISTS usr_stat (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    dept_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
    
    -- Answer tracking
    user_answer TEXT,
    is_correct BOOLEAN,
    score_earned INTEGER DEFAULT 0,
    
    -- Timestamps
    answered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_usr_stat_user_id ON usr_stat(user_id);
CREATE INDEX IF NOT EXISTS idx_usr_stat_dept_id ON usr_stat(dept_id);
CREATE INDEX IF NOT EXISTS idx_usr_stat_question_id ON usr_stat(question_id);
CREATE INDEX IF NOT EXISTS idx_usr_stat_is_correct ON usr_stat(is_correct);

-- Add RLS policies
ALTER TABLE usr_stat ENABLE ROW LEVEL SECURITY;

-- Users can view their own stats
CREATE POLICY "Users can view own stats" ON usr_stat
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own stats
CREATE POLICY "Users can insert own stats" ON usr_stat
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admins can view all stats
CREATE POLICY "Admins can view all stats" ON usr_stat
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Verify table was created
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'usr_stat'
ORDER BY ordinal_position;
