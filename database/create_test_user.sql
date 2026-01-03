-- ============================================
-- CREATE TEST USERS FOR DEMO
-- ============================================

-- Note: You need to create users in Supabase Auth first
-- Then run this script to create their profiles

-- ============================================
-- STEP 1: Create user in Supabase Auth UI
-- ============================================
-- Go to: Authentication → Users → Add User
-- Email: naik.abhira2326@gmail.com
-- Password: (your password)
-- Copy the user_id after creation

-- ============================================
-- STEP 2: Insert profile (replace user_id)
-- ============================================

-- For the user you just created, insert profile:
INSERT INTO profiles (user_id, email, role)
VALUES (
    'REPLACE-WITH-YOUR-USER-ID-FROM-AUTH',  -- Get this from Auth → Users
    'naik.abhira2326@gmail.com',
    'admin'  -- or 'user'
);

-- ============================================
-- ALTERNATIVE: If you already have auth users
-- ============================================

-- Check existing auth users:
-- SELECT id, email FROM auth.users;

-- Then create profiles for them:
-- INSERT INTO profiles (user_id, email, role)
-- SELECT id, email, 'user' as role
-- FROM auth.users
-- WHERE email = 'naik.abhira2326@gmail.com';

-- ============================================
-- SAMPLE DATA: Create a test department
-- ============================================

INSERT INTO departments (title, description, category, subcategory, tags, levels)
VALUES (
    'Orientation',
    'New employee orientation program',
    'Onboarding',
    'General',
    '["orientation", "onboarding", "basics"]'::jsonb,
    '[
        {"level_id": "1", "level_number": 1, "title": "Basics", "category": "Introduction"},
        {"level_id": "2", "level_number": 2, "title": "Intermediate", "category": "Core Skills"},
        {"level_id": "3", "level_number": 3, "title": "Advanced", "category": "Expert"}
    ]'::jsonb
)
RETURNING id;

-- Save the department ID from above, then create dept_levels:
-- Replace 'DEPT-ID-HERE' with the actual ID

INSERT INTO dept_levels (dept_id, level_id, title, category, level_number)
VALUES 
    ('DEPT-ID-HERE', gen_random_uuid(), 'Basics', 'Introduction', 1),
    ('DEPT-ID-HERE', gen_random_uuid(), 'Intermediate', 'Core Skills', 2),
    ('DEPT-ID-HERE', gen_random_uuid(), 'Advanced', 'Expert', 3);

-- ============================================
-- SAMPLE DATA: Create test questions
-- ============================================

-- Get the MCQ question type ID
-- SELECT id FROM question_types WHERE type = 'mcq';

INSERT INTO questions (type_id, dept_id, category, title, description, difficulty, points)
VALUES (
    (SELECT id FROM question_types WHERE type = 'mcq'),
    'DEPT-ID-HERE',  -- Replace with your department ID
    'General Knowledge',
    'What is the company mission?',
    'Select the correct answer',
    'easy',
    10
);

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check if profile was created:
SELECT * FROM profiles WHERE email = 'naik.abhira2326@gmail.com';

-- Check departments:
SELECT * FROM departments;

-- Check questions:
SELECT * FROM questions;

-- ============================================
-- NOTES
-- ============================================
-- 1. Create user in Supabase Auth UI first
-- 2. Copy the user_id
-- 3. Run the INSERT INTO profiles with that user_id
-- 4. Then you can login with that email/password
