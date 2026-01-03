-- ============================================
-- SIMPLE FIX: Setup for Supabase Auth
-- ============================================
-- Run this complete script in Supabase SQL Editor

-- Step 1: Clean existing data (ignore errors if tables don't exist)
DO $$ 
BEGIN
    TRUNCATE TABLE IF EXISTS user_progress CASCADE;
    TRUNCATE TABLE IF EXISTS user_assignments CASCADE;
    TRUNCATE TABLE IF EXISTS quiz_progress CASCADE;
    TRUNCATE TABLE IF EXISTS profiles CASCADE;
    DROP TABLE IF EXISTS users CASCADE;
EXCEPTION WHEN OTHERS THEN
    NULL; -- Ignore errors
END $$;

-- Step 2: Create profiles table for Supabase Auth
DROP TABLE IF EXISTS profiles CASCADE;
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT UNIQUE,
    phone TEXT,
    avatar_url TEXT,
    bio TEXT,
    date_of_birth DATE,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create user_progress table
CREATE TABLE IF NOT EXISTS user_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    total_assignments INTEGER DEFAULT 0,
    completed_assignments INTEGER DEFAULT 0,
    total_marks INTEGER DEFAULT 0,
    orientation_completed BOOLEAN DEFAULT FALSE,
    current_pathway_id UUID REFERENCES pathways(id) ON DELETE SET NULL,
    current_level INTEGER DEFAULT 1,
    current_score INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create user_assignments table
CREATE TABLE IF NOT EXISTS user_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    assignment_name TEXT NOT NULL,
    pathway_level_id UUID REFERENCES pathway_levels(id) ON DELETE SET NULL,
    orientation_completed BOOLEAN DEFAULT FALSE,
    marks INTEGER DEFAULT 0,
    max_marks INTEGER DEFAULT 100,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_assignments ENABLE ROW LEVEL SECURITY;

-- Step 6: Create RLS policies for profiles
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Step 7: Create RLS policies for user_progress
CREATE POLICY "Users can view own progress" ON user_progress
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON user_progress
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON user_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Step 8: Create RLS policies for user_assignments
CREATE POLICY "Users can view own assignments" ON user_assignments
    FOR SELECT USING (auth.uid() = user_id);

-- Step 9: Create indexes
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_assignments_user_id ON user_assignments(user_id);

-- Step 10: Insert pathways
INSERT INTO pathways (name, description) VALUES
    ('Communication', 'Master the art of effective communication'),
    ('Creative', 'Unleash your creative potential'),
    ('Production', 'Learn production management skills'),
    ('Ideation', 'Develop innovative thinking abilities')
ON CONFLICT (name) DO NOTHING;

-- Done! Now test signup from your app
SELECT 'Database setup complete for Supabase Auth!' as status;
