-- ============================================
-- SCHEMA: ENEPL App Database
-- ============================================
-- This file contains all table definitions and structure
-- Run this first before seed.sql

-- ============================================
-- ENUMS
-- ============================================

-- Create user role enum
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('user', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- CORE TABLES
-- ============================================

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    current_level INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create profiles table (extended with role)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT UNIQUE,
    phone TEXT,
    avatar_url TEXT,
    bio TEXT,
    date_of_birth DATE,
    role user_role DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create quiz_progress table for tracking quiz attempts
CREATE TABLE IF NOT EXISTS quiz_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    level INTEGER NOT NULL,
    score INTEGER NOT NULL,
    total_questions INTEGER NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PATHWAY SYSTEM TABLES
-- ============================================

-- Create pathways table (departments)
CREATE TABLE IF NOT EXISTS pathways (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create pathway_levels table
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

-- ============================================
-- USER ASSIGNMENT AND PROGRESS TABLES
-- ============================================

-- Create user_assignments table
CREATE TABLE IF NOT EXISTS user_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    assignment_name TEXT NOT NULL,
    pathway_level_id UUID REFERENCES pathway_levels(id) ON DELETE SET NULL,
    orientation_completed BOOLEAN DEFAULT FALSE,
    marks INTEGER DEFAULT 0,
    max_marks INTEGER DEFAULT 100,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_progress table
CREATE TABLE IF NOT EXISTS user_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    total_assignments INTEGER DEFAULT 0,
    completed_assignments INTEGER DEFAULT 0,
    total_marks INTEGER DEFAULT 0,
    orientation_completed BOOLEAN DEFAULT FALSE,
    current_pathway_id UUID REFERENCES pathways(id) ON DELETE SET NULL,
    current_level INTEGER DEFAULT 1,
    current_score INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES for Performance
-- ============================================

-- Users and Profiles
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Quiz Progress
CREATE INDEX IF NOT EXISTS idx_quiz_progress_user_id ON quiz_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_progress_level ON quiz_progress(level);
CREATE INDEX IF NOT EXISTS idx_quiz_progress_completed_at ON quiz_progress(completed_at);

-- Pathways
CREATE INDEX IF NOT EXISTS idx_pathways_name ON pathways(name);
CREATE INDEX IF NOT EXISTS idx_pathway_levels_pathway_id ON pathway_levels(pathway_id);
CREATE INDEX IF NOT EXISTS idx_pathway_levels_level_number ON pathway_levels(level_number);

-- User Assignments and Progress
CREATE INDEX IF NOT EXISTS idx_user_assignments_user_id ON user_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_assignments_completed_at ON user_assignments(completed_at);
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_pathway_id ON user_progress(current_pathway_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = user_uuid AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user progress when assignments change
CREATE OR REPLACE FUNCTION update_user_progress_from_assignments()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_total_assignments INTEGER;
    v_completed_assignments INTEGER;
    v_total_marks INTEGER;
    v_orientation_completed BOOLEAN;
BEGIN
    -- Get user_id from the assignment
    IF TG_OP = 'DELETE' THEN
        v_user_id := OLD.user_id;
    ELSE
        v_user_id := NEW.user_id;
    END IF;

    -- Calculate aggregated values
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE completed_at IS NOT NULL),
        COALESCE(SUM(marks), 0),
        BOOL_OR(orientation_completed)
    INTO 
        v_total_assignments,
        v_completed_assignments,
        v_total_marks,
        v_orientation_completed
    FROM user_assignments
    WHERE user_id = v_user_id;

    -- Update or insert user_progress
    INSERT INTO user_progress (
        user_id, 
        total_assignments, 
        completed_assignments, 
        total_marks, 
        orientation_completed,
        updated_at
    )
    VALUES (
        v_user_id,
        v_total_assignments,
        v_completed_assignments,
        v_total_marks,
        COALESCE(v_orientation_completed, FALSE),
        NOW()
    )
    ON CONFLICT (user_id) 
    DO UPDATE SET
        total_assignments = v_total_assignments,
        completed_assignments = v_completed_assignments,
        total_marks = v_total_marks,
        orientation_completed = COALESCE(v_orientation_completed, FALSE),
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE pathways ENABLE ROW LEVEL SECURITY;
ALTER TABLE pathway_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow read access to all users" ON users;
DROP POLICY IF EXISTS "Allow users to update own data" ON users;
DROP POLICY IF EXISTS "Allow insert for new users" ON users;
DROP POLICY IF EXISTS "Allow users to read own profile" ON profiles;
DROP POLICY IF EXISTS "Allow users to update own profile" ON profiles;
DROP POLICY IF EXISTS "Allow users to insert own profile" ON profiles;
DROP POLICY IF EXISTS "Allow users to read own progress" ON quiz_progress;
DROP POLICY IF EXISTS "Allow users to insert own progress" ON quiz_progress;

-- ============================================
-- RLS POLICIES: Users Table
-- ============================================

CREATE POLICY "Allow read access to all users" ON users
    FOR SELECT USING (true);

CREATE POLICY "Allow users to update own data" ON users
    FOR UPDATE USING (true);

CREATE POLICY "Allow insert for new users" ON users
    FOR INSERT WITH CHECK (true);

-- ============================================
-- RLS POLICIES: Profiles Table
-- ============================================

CREATE POLICY "Allow users to read own profile" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Allow users to update own profile" ON profiles
    FOR UPDATE USING (true);

CREATE POLICY "Allow users to insert own profile" ON profiles
    FOR INSERT WITH CHECK (true);

-- ============================================
-- RLS POLICIES: Quiz Progress Table
-- ============================================

CREATE POLICY "Allow users to read own progress" ON quiz_progress
    FOR SELECT USING (true);

CREATE POLICY "Allow users to insert own progress" ON quiz_progress
    FOR INSERT WITH CHECK (true);

-- ============================================
-- RLS POLICIES: Pathways Table
-- ============================================

CREATE POLICY "Allow all users to read pathways" ON pathways
    FOR SELECT USING (true);

CREATE POLICY "Allow admins to insert pathways" ON pathways
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Allow admins to update pathways" ON pathways
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Allow admins to delete pathways" ON pathways
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- ============================================
-- RLS POLICIES: Pathway Levels Table
-- ============================================

CREATE POLICY "Allow all users to read pathway levels" ON pathway_levels
    FOR SELECT USING (true);

CREATE POLICY "Allow admins to insert pathway levels" ON pathway_levels
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Allow admins to update pathway levels" ON pathway_levels
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Allow admins to delete pathway levels" ON pathway_levels
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- ============================================
-- RLS POLICIES: User Assignments Table
-- ============================================

CREATE POLICY "Allow users to read own assignments" ON user_assignments
    FOR SELECT USING (true);

CREATE POLICY "Allow admins to insert assignments" ON user_assignments
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Allow admins to update assignments" ON user_assignments
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Allow admins to delete assignments" ON user_assignments
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- ============================================
-- RLS POLICIES: User Progress Table
-- ============================================

CREATE POLICY "Allow users to read own user progress" ON user_progress
    FOR SELECT USING (true);

CREATE POLICY "Allow users to update own user progress" ON user_progress
    FOR UPDATE USING (true);

CREATE POLICY "Allow users to insert own user progress" ON user_progress
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow admins to read all user progress" ON user_progress
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- ============================================
-- TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for users table
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Triggers for profiles table
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Triggers for pathways table
DROP TRIGGER IF EXISTS update_pathways_updated_at ON pathways;
CREATE TRIGGER update_pathways_updated_at
    BEFORE UPDATE ON pathways
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Triggers for pathway_levels table
DROP TRIGGER IF EXISTS update_pathway_levels_updated_at ON pathway_levels;
CREATE TRIGGER update_pathway_levels_updated_at
    BEFORE UPDATE ON pathway_levels
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Triggers for user_assignments table
DROP TRIGGER IF EXISTS update_user_assignments_updated_at ON user_assignments;
CREATE TRIGGER update_user_assignments_updated_at
    BEFORE UPDATE ON user_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update user_progress when assignments change
DROP TRIGGER IF EXISTS trigger_update_user_progress ON user_assignments;
CREATE TRIGGER trigger_update_user_progress
    AFTER INSERT OR UPDATE OR DELETE ON user_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_user_progress_from_assignments();
