-- Create a fresh test user with no pathway assignments

-- Step 1: Check if test user already exists
SELECT id, email FROM auth.users WHERE email = 'testuser@example.com';

-- Step 2: If user doesn't exist, you'll need to create via signup in the app
-- Use these credentials:
-- Email: testuser@example.com
-- Password: Test@123
-- Full Name: Test User

-- Step 3: After creating the user via signup, verify they have no pathway assignments
SELECT 
  u.email,
  COUNT(up.pathway_id) as pathway_count
FROM auth.users u
LEFT JOIN user_pathway up ON u.id = up.user_id
WHERE u.email = 'testuser@example.com'
GROUP BY u.email;

-- Expected result: pathway_count = 0

-- Step 4: Verify no user progress exists
SELECT *
FROM user_progress
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'testuser@example.com');

-- Expected result: No rows
