-- Simplify profiles table to only keep essential fields
-- Keep: id, user_id, email, role
-- Remove: full_name, phone, created_at, updated_at

-- Step 1: Drop unnecessary columns
ALTER TABLE profiles DROP COLUMN IF EXISTS full_name;
ALTER TABLE profiles DROP COLUMN IF EXISTS phone;
ALTER TABLE profiles DROP COLUMN IF EXISTS created_at;
ALTER TABLE profiles DROP COLUMN IF EXISTS updated_at;

-- Step 2: Add email column if it doesn't exist
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- Step 3: Populate email from auth.users
UPDATE profiles p
SET email = u.email
FROM auth.users u
WHERE p.user_id = u.id;

-- Step 4: Make email NOT NULL
ALTER TABLE profiles ALTER COLUMN email SET NOT NULL;

-- Step 5: Add unique constraint on email
ALTER TABLE profiles ADD CONSTRAINT profiles_email_unique UNIQUE (email);

-- Final structure of profiles table:
-- - id (UUID, primary key)
-- - user_id (UUID, references auth.users)
-- - email (TEXT, not null, unique)
-- - role (TEXT, default 'user')
