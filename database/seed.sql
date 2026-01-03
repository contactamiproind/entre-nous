-- ============================================
-- SEED DATA: ENEPL App Initial Data
-- ============================================
-- This file contains seed data for testing and development
-- Run this after schema.sql

-- Clear existing data (optional - comment out in production)
TRUNCATE users, profiles, quiz_progress, pathways, pathway_levels, user_assignments, user_progress CASCADE;

-- ============================================
-- Insert Default Users
-- ============================================

INSERT INTO users (id, username, password, is_admin, current_level) 
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'user', 'user123', FALSE, 1),
    ('00000000-0000-0000-0000-000000000002', 'admin', 'admin123', TRUE, 1)
ON CONFLICT (username) DO UPDATE 
SET 
    password = EXCLUDED.password,
    is_admin = EXCLUDED.is_admin,
    current_level = EXCLUDED.current_level;

-- ============================================
-- Insert Default Profiles (with roles)
-- ============================================

INSERT INTO profiles (user_id, full_name, email, phone, bio, role) 
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'Test User', 'user@example.com', '+1234567890', 'Regular quiz user', 'user'),
    ('00000000-0000-0000-0000-000000000002', 'Admin User', 'admin@example.com', '+1234567891', 'System administrator', 'admin')
ON CONFLICT (user_id) DO UPDATE 
SET 
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    bio = EXCLUDED.bio,
    role = EXCLUDED.role;

-- ============================================
-- Insert Sample Quiz Progress
-- ============================================

-- No sample quiz progress data for initial setup
-- Users will create their own progress as they complete quizzes

-- ============================================
-- Insert Pathways (4 Departments)
-- ============================================

INSERT INTO pathways (id, name, description) 
VALUES 
    ('10000000-0000-0000-0000-000000000001', 'Communication', 'Master the art of effective communication, presentation, and interpersonal skills'),
    ('10000000-0000-0000-0000-000000000002', 'Creative', 'Develop creative thinking, design, and innovative problem-solving abilities'),
    ('10000000-0000-0000-0000-000000000003', 'Production', 'Learn production management, execution, and delivery excellence'),
    ('10000000-0000-0000-0000-000000000004', 'Ideation', 'Cultivate ideation, brainstorming, and conceptual development skills')
ON CONFLICT (name) DO UPDATE 
SET description = EXCLUDED.description;

-- ============================================
-- Insert Pathway Levels (Different structures per department)
-- ============================================

-- Communication Pathway: 5 Levels
INSERT INTO pathway_levels (pathway_id, level_number, level_name, required_score, description) 
VALUES 
    ('10000000-0000-0000-0000-000000000001', 1, 'Foundation', 0, 'Basic communication fundamentals'),
    ('10000000-0000-0000-0000-000000000001', 2, 'Intermediate', 100, 'Developing presentation skills'),
    ('10000000-0000-0000-0000-000000000001', 3, 'Advanced', 250, 'Advanced public speaking'),
    ('10000000-0000-0000-0000-000000000001', 4, 'Expert', 450, 'Leadership communication'),
    ('10000000-0000-0000-0000-000000000001', 5, 'Master', 700, 'Strategic communication mastery')
ON CONFLICT (pathway_id, level_number) DO UPDATE 
SET level_name = EXCLUDED.level_name, required_score = EXCLUDED.required_score, description = EXCLUDED.description;

-- Creative Pathway: 6 Levels
INSERT INTO pathway_levels (pathway_id, level_number, level_name, required_score, description) 
VALUES 
    ('10000000-0000-0000-0000-000000000002', 1, 'Explorer', 0, 'Discovering creative potential'),
    ('10000000-0000-0000-0000-000000000002', 2, 'Apprentice', 80, 'Learning design basics'),
    ('10000000-0000-0000-0000-000000000002', 3, 'Craftsman', 200, 'Developing unique style'),
    ('10000000-0000-0000-0000-000000000002', 4, 'Innovator', 350, 'Creating original work'),
    ('10000000-0000-0000-0000-000000000002', 5, 'Visionary', 550, 'Leading creative projects'),
    ('10000000-0000-0000-0000-000000000002', 6, 'Maestro', 800, 'Creative excellence and mentorship')
ON CONFLICT (pathway_id, level_number) DO UPDATE 
SET level_name = EXCLUDED.level_name, required_score = EXCLUDED.required_score, description = EXCLUDED.description;

-- Production Pathway: 4 Levels
INSERT INTO pathway_levels (pathway_id, level_number, level_name, required_score, description) 
VALUES 
    ('10000000-0000-0000-0000-000000000003', 1, 'Coordinator', 0, 'Basic production coordination'),
    ('10000000-0000-0000-0000-000000000003', 2, 'Manager', 150, 'Managing production workflows'),
    ('10000000-0000-0000-0000-000000000003', 3, 'Director', 400, 'Directing complex productions'),
    ('10000000-0000-0000-0000-000000000003', 4, 'Executive Producer', 750, 'Strategic production leadership')
ON CONFLICT (pathway_id, level_number) DO UPDATE 
SET level_name = EXCLUDED.level_name, required_score = EXCLUDED.required_score, description = EXCLUDED.description;

-- Ideation Pathway: 5 Levels
INSERT INTO pathway_levels (pathway_id, level_number, level_name, required_score, description) 
VALUES 
    ('10000000-0000-0000-0000-000000000004', 1, 'Thinker', 0, 'Basic brainstorming techniques'),
    ('10000000-0000-0000-0000-000000000004', 2, 'Conceptualizer', 120, 'Developing concepts'),
    ('10000000-0000-0000-0000-000000000004', 3, 'Strategist', 280, 'Strategic thinking'),
    ('10000000-0000-0000-0000-000000000004', 4, 'Architect', 500, 'Designing comprehensive solutions'),
    ('10000000-0000-0000-0000-000000000004', 5, 'Thought Leader', 800, 'Innovation and thought leadership')
ON CONFLICT (pathway_id, level_number) DO UPDATE 
SET level_name = EXCLUDED.level_name, required_score = EXCLUDED.required_score, description = EXCLUDED.description;

-- ============================================
-- Insert Sample User Assignments
-- ============================================

-- Regular user starts with orientation assignment
-- Marks = 0 initially, admin will update when user completes it
INSERT INTO user_assignments (user_id, assignment_name, pathway_level_id, orientation_completed, marks, max_marks, completed_at) 
VALUES 
    -- Orientation assignment - NOT YET COMPLETED
    ('00000000-0000-0000-0000-000000000001', 'Orientation Program', NULL, TRUE, 0, 100, NULL)
ON CONFLICT DO NOTHING;

-- Example: If admin later marks orientation as complete with 95 marks:
-- UPDATE user_assignments 
-- SET marks = 95, completed_at = NOW() 
-- WHERE user_id = '00000000-0000-0000-0000-000000000001' 
--   AND orientation_completed = TRUE;

-- ============================================
-- Insert User Progress (will be auto-updated by trigger)
-- ============================================

-- Initialize user progress - regular user starts with:
-- - orientation_completed = FALSE
-- - No pathway selected (NULL)
-- - Level 1, Score 0
INSERT INTO user_progress (user_id, orientation_completed, current_pathway_id, current_level, current_score) 
VALUES 
    ('00000000-0000-0000-0000-000000000001', FALSE, NULL, 1, 0)
ON CONFLICT (user_id) DO UPDATE 
SET 
    orientation_completed = EXCLUDED.orientation_completed,
    current_pathway_id = EXCLUDED.current_pathway_id,
    current_level = EXCLUDED.current_level,
    current_score = EXCLUDED.current_score;

-- ============================================
-- Verification Queries (Optional)
-- ============================================

-- Uncomment to verify data was inserted correctly
-- SELECT 'Users Count:' as info, COUNT(*) as count FROM users;
-- SELECT 'Profiles Count:' as info, COUNT(*) as count FROM profiles;
-- SELECT 'Pathways Count:' as info, COUNT(*) as count FROM pathways;
-- SELECT 'Pathway Levels Count:' as info, COUNT(*) as count FROM pathway_levels;
-- SELECT 'User Assignments Count:' as info, COUNT(*) as count FROM user_assignments;
-- SELECT 'User Progress Count:' as info, COUNT(*) as count FROM user_progress;
