-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    current_level INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_quiz_progress_user_id ON quiz_progress(user_id);

-- Insert default users
INSERT INTO users (username, password, is_admin, current_level) 
VALUES 
    ('user', 'user123', FALSE, 1),
    ('admin', 'admin123', TRUE, 1)
ON CONFLICT (username) DO NOTHING;

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_progress ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
-- Allow all users to read all user data (needed for admin panel)
CREATE POLICY "Allow read access to all users" ON users
    FOR SELECT USING (true);

-- Allow users to update their own data
CREATE POLICY "Allow users to update own data" ON users
    FOR UPDATE USING (true);

-- Allow insert for new users (registration)
CREATE POLICY "Allow insert for new users" ON users
    FOR INSERT WITH CHECK (true);

-- RLS Policies for quiz_progress table
-- Allow users to read their own progress
CREATE POLICY "Allow users to read own progress" ON quiz_progress
    FOR SELECT USING (true);

-- Allow users to insert their own progress
CREATE POLICY "Allow users to insert own progress" ON quiz_progress
    FOR INSERT WITH CHECK (true);
