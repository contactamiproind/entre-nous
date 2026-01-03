-- ============================================
-- QUICK SETUP - Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Check if user exists in auth
SELECT id, email FROM auth.users WHERE email = 'naik.abhira2326@gmail.com';

-- If user doesn't exist, you need to create it in Supabase UI first:
-- Go to Authentication → Users → Add User
-- Email: naik.abhira2326@gmail.com
-- Password: abhira26
-- Check "Auto Confirm User"

-- Step 2: Create profile for existing auth user
INSERT INTO profiles (user_id, email, role)
SELECT id, email, 'user' as role
FROM auth.users
WHERE email = 'naik.abhira2326@gmail.com'
ON CONFLICT (user_id) DO NOTHING;

-- Step 3: Create admin user profile (if admin exists in auth)
INSERT INTO profiles (user_id, email, role)
SELECT id, email, 'admin' as role
FROM auth.users
WHERE email = 'admin@enepl.com'
ON CONFLICT (user_id) DO NOTHING;

-- Step 4: Verify profiles were created
SELECT p.*, u.email 
FROM profiles p
JOIN auth.users u ON p.user_id = u.id
WHERE u.email IN ('naik.abhira2326@gmail.com', 'admin@enepl.com');

-- Step 5: Create sample department
INSERT INTO departments (title, description, category, subcategory, tags, levels)
VALUES (
    'Orientation',
    'New employee orientation program',
    'Onboarding',
    'General',
    '["orientation", "onboarding"]'::jsonb,
    '[
        {"level_id": "1", "level_number": 1, "title": "Basics", "category": "Introduction"},
        {"level_id": "2", "level_number": 2, "title": "Intermediate", "category": "Skills"}
    ]'::jsonb
)
ON CONFLICT DO NOTHING
RETURNING id, title;

-- Step 6: Create dept_levels
DO $$
DECLARE
    dept_id UUID;
BEGIN
    SELECT id INTO dept_id FROM departments WHERE title = 'Orientation' LIMIT 1;
    
    IF dept_id IS NOT NULL THEN
        INSERT INTO dept_levels (dept_id, level_id, title, category, level_number)
        VALUES 
            (dept_id, gen_random_uuid(), 'Basics', 'Introduction', 1),
            (dept_id, gen_random_uuid(), 'Intermediate', 'Skills', 2)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- Step 7: Create sample questions
DO $$
DECLARE
    dept_id UUID;
    mcq_type_id UUID;
BEGIN
    SELECT id INTO dept_id FROM departments WHERE title = 'Orientation' LIMIT 1;
    SELECT id INTO mcq_type_id FROM question_types WHERE type = 'mcq' LIMIT 1;
    
    IF dept_id IS NOT NULL AND mcq_type_id IS NOT NULL THEN
        INSERT INTO questions (type_id, dept_id, category, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, dept_id, 'Company Culture', 'What is our company mission?', 'Select the correct answer', 'easy', 10),
            (mcq_type_id, dept_id, 'Company Culture', 'What are our core values?', 'Choose the best answer', 'easy', 10),
            (mcq_type_id, dept_id, 'Policies', 'What is the dress code?', 'Select the option', 'medium', 15)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- Step 8: Assign pathway to user
DO $$
DECLARE
    user_uuid UUID;
    dept_uuid UUID;
    admin_uuid UUID;
BEGIN
    SELECT id INTO user_uuid FROM auth.users WHERE email = 'naik.abhira2326@gmail.com';
    SELECT id INTO dept_uuid FROM departments WHERE title = 'Orientation';
    SELECT id INTO admin_uuid FROM auth.users WHERE email = 'admin@enepl.com';
    
    IF user_uuid IS NOT NULL AND dept_uuid IS NOT NULL THEN
        INSERT INTO user_pathway (user_id, pathway_id, pathway_name, assigned_by, is_current)
        VALUES (user_uuid, dept_uuid, 'Orientation', admin_uuid, true)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- Final verification
SELECT 'Setup Complete!' as status;
SELECT 'Profiles' as table_name, COUNT(*) as count FROM profiles
UNION ALL
SELECT 'Departments', COUNT(*) FROM departments
UNION ALL
SELECT 'Dept Levels', COUNT(*) FROM dept_levels
UNION ALL
SELECT 'Questions', COUNT(*) FROM questions
UNION ALL
SELECT 'User Pathways', COUNT(*) FROM user_pathway;
