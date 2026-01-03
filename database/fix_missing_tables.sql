-- ============================================
-- FIX: Create missing tables
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Create pathway_levels table
CREATE TABLE IF NOT EXISTS pathway_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pathway_id UUID REFERENCES pathways(id) ON DELETE CASCADE,
    level_number INTEGER NOT NULL,
    level_name TEXT NOT NULL,
    required_score INTEGER NOT NULL DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(pathway_id, level_number)
);

-- 2. Create questions table
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    level_id UUID REFERENCES pathway_levels(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    options TEXT[] NOT NULL,
    correct_answer_index INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- RLS POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE pathway_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

-- Policies for pathway_levels
DROP POLICY IF EXISTS "Allow all users to read pathway levels" ON pathway_levels;
CREATE POLICY "Allow all users to read pathway levels" ON pathway_levels
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow admins to insert pathway levels" ON pathway_levels;
CREATE POLICY "Allow admins to insert pathway levels" ON pathway_levels
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Allow admins to update pathway levels" ON pathway_levels;
CREATE POLICY "Allow admins to update pathway levels" ON pathway_levels
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Allow admins to delete pathway levels" ON pathway_levels;
CREATE POLICY "Allow admins to delete pathway levels" ON pathway_levels
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Policies for questions
DROP POLICY IF EXISTS "Allow all users to read questions" ON questions;
CREATE POLICY "Allow all users to read questions" ON questions
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow admins to insert questions" ON questions;
CREATE POLICY "Allow admins to insert questions" ON questions
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Allow admins to update questions" ON questions;
CREATE POLICY "Allow admins to update questions" ON questions
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Allow admins to delete questions" ON questions;
CREATE POLICY "Allow admins to delete questions" ON questions
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );
