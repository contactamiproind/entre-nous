-- Add created_by and updated_by to profiles table (FIXED)
-- Run this in Supabase SQL Editor

-- Step 1: Add 'created_by' column (admin who created the profile)
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(user_id);

-- Step 2: Add 'updated_by' column (admin who last updated the profile)
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES profiles(user_id);

-- Step 3: Set default values for existing records
-- For admin profiles, set created_by to themselves (self-created)
UPDATE profiles
SET created_by = user_id
WHERE role = 'admin' AND created_by IS NULL;

-- For user profiles, set created_by to first admin
UPDATE profiles
SET created_by = (
  SELECT user_id FROM profiles WHERE role = 'admin' LIMIT 1
)
WHERE role = 'user' AND created_by IS NULL;

-- Set updated_by same as created_by for existing profiles
UPDATE profiles
SET updated_by = created_by
WHERE updated_by IS NULL;

-- Step 4: Verify the changes
SELECT 
  user_id,
  email,
  role,
  created_by,
  updated_by
FROM profiles
ORDER BY role DESC
LIMIT 10;
