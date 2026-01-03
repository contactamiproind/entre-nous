-- Check the specific user account status

-- Check auth.users for this email
SELECT 
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  confirmed_at,
  last_sign_in_at,
  created_at,
  banned_until,
  deleted_at
FROM auth.users
WHERE email = 'naik.abhira23261@gmail.com';

-- Check if profile exists
SELECT *
FROM profiles
WHERE email = 'naik.abhira23261@gmail.com';

-- If you need to reset the password for testing, uncomment and run:
-- Note: This will set the password to 'password123'
-- You'll need to generate a proper hash, or use Supabase dashboard to reset password

-- Alternative: Delete this user and create fresh
-- DELETE FROM profiles WHERE email = 'naik.abhira23261@gmail.com';
-- DELETE FROM auth.users WHERE email = 'naik.abhira23261@gmail.com';
