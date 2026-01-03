-- Check user account status in Supabase

-- Check if user exists in auth.users
SELECT 
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at,
  confirmed_at
FROM auth.users
WHERE email LIKE '%abhira%'
ORDER BY created_at DESC;

-- Check if profile exists
SELECT 
  user_id,
  email,
  role,
  created_at
FROM profiles
WHERE email LIKE '%abhira%'
ORDER BY created_at DESC;

-- If you need to manually confirm the email (for testing), run this:
-- UPDATE auth.users 
-- SET email_confirmed_at = NOW(), 
--     confirmed_at = NOW()
-- WHERE email = 'naik.abhira23261@gmail.com';
