-- ============================================
-- ENSURE DEMO CREDENTIALS IN SUPABASE
-- ============================================
-- Run this script in your Supabase SQL Editor to ensure demo users exist
-- This script is safe to run multiple times (it uses ON CONFLICT)

-- ============================================
-- Insert Demo Users
-- ============================================

INSERT INTO users (id, username, password, is_admin, current_level) 
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'user', 'user123', FALSE, 1),
    ('00000000-0000-0000-0000-000000000002', 'admin', 'admin123', TRUE, 1),
    ('00000000-0000-0000-0000-000000000003', 'john', 'john123', FALSE, 3),
    ('00000000-0000-0000-0000-000000000004', 'sarah', 'sarah123', FALSE, 2)
ON CONFLICT (username) DO UPDATE 
SET 
    password = EXCLUDED.password,
    is_admin = EXCLUDED.is_admin,
    current_level = EXCLUDED.current_level;

-- ============================================
-- Insert Demo Profiles
-- ============================================

INSERT INTO profiles (user_id, full_name, email, phone, bio) 
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'Test User', 'user@example.com', '+1234567890', 'Regular quiz user'),
    ('00000000-0000-0000-0000-000000000002', 'Admin User', 'admin@example.com', '+1234567891', 'System administrator'),
    ('00000000-0000-0000-0000-000000000003', 'John Doe', 'john@example.com', '+1234567892', 'Quiz enthusiast'),
    ('00000000-0000-0000-0000-000000000004', 'Sarah Smith', 'sarah@example.com', '+1234567893', 'Learning and growing')
ON CONFLICT (user_id) DO UPDATE 
SET 
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    bio = EXCLUDED.bio;

-- ============================================
-- Verify Data
-- ============================================

-- Check users
SELECT 'Users:' as table_name, COUNT(*) as count FROM users;
SELECT * FROM users ORDER BY username;

-- Check profiles
SELECT 'Profiles:' as table_name, COUNT(*) as count FROM profiles;
SELECT 
    u.username,
    p.full_name,
    p.email,
    p.phone
FROM users u
LEFT JOIN profiles p ON u.id = p.user_id
ORDER BY u.username;
