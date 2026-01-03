-- Check if the user was created successfully
SELECT * FROM profiles ORDER BY created_at DESC LIMIT 5;

-- Check if there are any users with role 'user'
SELECT * FROM profiles WHERE role = 'user';

-- Check all profiles regardless of role
SELECT user_id, email, role, created_at, manually_created FROM profiles;
