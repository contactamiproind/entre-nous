-- ============================================
-- SETUP TEST USERS - COMPLETE GUIDE
-- ============================================

-- ============================================
-- STEP 1: CREATE USERS IN SUPABASE AUTH UI
-- ============================================

/*
You MUST create these users in Supabase Dashboard first:

1. Go to: Supabase Dashboard → Authentication → Users
2. Click "Add User" (or "Invite User")
3. Create these two users:

USER 1 (Regular User):
- Email: naik.abhira2326@gmail.com
- Password: abhira26
- Auto Confirm User: YES (check this box)

USER 2 (Admin):
- Email: admin@enepl.com
- Password: Admin@123
- Auto Confirm User: YES (check this box)

4. After creating, COPY the User IDs (UUIDs) for both users
*/

-- ============================================
-- STEP 2: CREATE PROFILES (Run this SQL)
-- ============================================

-- Replace 'USER-1-UUID-HERE' and 'USER-2-UUID-HERE' with actual UUIDs from Step 1

-- Regular User Profile
INSERT INTO profiles (user_id, email, role)
VALUES (
    'USER-1-UUID-HERE',  -- Replace with UUID from auth.users for naik.abhira2326@gmail.com
    'naik.abhira2326@gmail.com',
    'user'
);

-- Admin User Profile
INSERT INTO profiles (user_id, email, role)
VALUES (
    'USER-2-UUID-HERE',  -- Replace with UUID from auth.users for admin@enepl.com
    'admin@enepl.com',
    'admin'
);

-- ============================================
-- ALTERNATIVE: AUTO-CREATE PROFILES
-- ============================================

-- If you've already created the users in Auth UI,
-- you can run this to automatically create their profiles:

INSERT INTO profiles (user_id, email, role)
SELECT 
    id,
    email,
    CASE 
        WHEN email = 'admin@enepl.com' THEN 'admin'
        ELSE 'user'
    END as role
FROM auth.users
WHERE email IN ('naik.abhira2326@gmail.com', 'admin@enepl.com')
ON CONFLICT (user_id) DO NOTHING;

-- ============================================
-- STEP 3: VERIFY USERS WERE CREATED
-- ============================================

-- Check auth users:
SELECT id, email, created_at 
FROM auth.users 
WHERE email IN ('naik.abhira2326@gmail.com', 'admin@enepl.com');

-- Check profiles:
SELECT * FROM profiles 
WHERE email IN ('naik.abhira2326@gmail.com', 'admin@enepl.com');

-- ============================================
-- STEP 4: CREATE SAMPLE DEPARTMENT
-- ============================================

-- Create Orientation department
INSERT INTO departments (title, description, category, subcategory, tags, levels)
VALUES (
    'Orientation',
    'New employee orientation program',
    'Onboarding',
    'General',
    '["orientation", "onboarding", "basics"]'::jsonb,
    '[
        {"level_id": "1", "level_number": 1, "title": "Basics", "category": "Introduction"},
        {"level_id": "2", "level_number": 2, "title": "Intermediate", "category": "Core Skills"}
    ]'::jsonb
)
RETURNING id, title;

-- Save the department ID, then create dept_levels
-- Replace 'DEPT-ID' with the ID from above

DO $$
DECLARE
    dept_id UUID;
BEGIN
    -- Get the Orientation department ID
    SELECT id INTO dept_id FROM departments WHERE title = 'Orientation' LIMIT 1;
    
    -- Create dept_levels
    INSERT INTO dept_levels (dept_id, level_id, title, category, level_number)
    VALUES 
        (dept_id, gen_random_uuid(), 'Basics', 'Introduction', 1),
        (dept_id, gen_random_uuid(), 'Intermediate', 'Core Skills', 2);
END $$;

-- ============================================
-- STEP 5: CREATE SAMPLE QUESTIONS
-- ============================================

DO $$
DECLARE
    dept_id UUID;
    mcq_type_id UUID;
BEGIN
    -- Get department and question type IDs
    SELECT id INTO dept_id FROM departments WHERE title = 'Orientation' LIMIT 1;
    SELECT id INTO mcq_type_id FROM question_types WHERE type = 'mcq' LIMIT 1;
    
    -- Create sample questions
    INSERT INTO questions (type_id, dept_id, category, title, description, difficulty, points)
    VALUES 
        (mcq_type_id, dept_id, 'Company Culture', 'What is our company mission?', 'Select the correct answer', 'easy', 10),
        (mcq_type_id, dept_id, 'Company Culture', 'What are our core values?', 'Choose the best answer', 'easy', 10),
        (mcq_type_id, dept_id, 'Policies', 'What is the dress code?', 'Select the appropriate option', 'medium', 15);
END $$;

-- ============================================
-- STEP 6: ASSIGN PATHWAY TO USER
-- ============================================

-- Assign Orientation to the regular user
DO $$
DECLARE
    user_uuid UUID;
    dept_uuid UUID;
    admin_uuid UUID;
BEGIN
    -- Get UUIDs
    SELECT id INTO user_uuid FROM auth.users WHERE email = 'naik.abhira2326@gmail.com';
    SELECT id INTO dept_uuid FROM departments WHERE title = 'Orientation';
    SELECT id INTO admin_uuid FROM auth.users WHERE email = 'admin@enepl.com';
    
    -- Assign pathway
    INSERT INTO user_pathway (user_id, pathway_id, pathway_name, assigned_by, is_current)
    VALUES (user_uuid, dept_uuid, 'Orientation', admin_uuid, true);
END $$;

-- ============================================
-- FINAL VERIFICATION
-- ============================================

-- Check everything is set up:
SELECT 'Auth Users' as check_type, COUNT(*) as count FROM auth.users WHERE email IN ('naik.abhira2326@gmail.com', 'admin@enepl.com')
UNION ALL
SELECT 'Profiles', COUNT(*) FROM profiles WHERE email IN ('naik.abhira2326@gmail.com', 'admin@enepl.com')
UNION ALL
SELECT 'Departments', COUNT(*) FROM departments
UNION ALL
SELECT 'Dept Levels', COUNT(*) FROM dept_levels
UNION ALL
SELECT 'Questions', COUNT(*) FROM questions
UNION ALL
SELECT 'User Pathways', COUNT(*) FROM user_pathway;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Setup complete!';
    RAISE NOTICE 'User login: naik.abhira2326@gmail.com / abhira26';
    RAISE NOTICE 'Admin login: admin@enepl.com / Admin@123';
    RAISE NOTICE 'You can now login to the app!';
END $$;
