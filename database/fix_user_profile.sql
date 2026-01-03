-- Check and fix user profile
-- Run this in Supabase SQL Editor

-- Check if profile exists for this user
SELECT 
  'Checking profile for naik.abhira@gmail.com' as step,
  COUNT(*) as profile_count
FROM profiles
WHERE email = 'naik.abhira@gmail.com';

-- Check auth.users table
SELECT 
  'Checking auth.users' as step,
  id,
  email,
  created_at
FROM auth.users
WHERE email = 'naik.abhira@gmail.com';

-- If profile doesn't exist, create it
-- Replace 'USER_ID_HERE' with the actual user_id from auth.users above
INSERT INTO profiles (user_id, email, role, orientation_completed)
SELECT 
  id,
  email,
  'user',
  false
FROM auth.users
WHERE email = 'naik.abhira@gmail.com'
AND NOT EXISTS (
  SELECT 1 FROM profiles WHERE profiles.user_id = auth.users.id
);

-- Verify profile was created
SELECT 
  'Profile created/verified' as status,
  user_id,
  email,
  role,
  orientation_completed
FROM profiles
WHERE email = 'naik.abhira@gmail.com';
