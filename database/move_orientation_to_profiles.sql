-- Move orientation_completed from user_progress to profiles
-- Orientation is a one-time user attribute, not pathway-specific

-- Step 1: Add orientation_completed to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS orientation_completed BOOLEAN DEFAULT FALSE;

-- Step 2: Migrate existing orientation data from user_progress to profiles
-- If ANY user_progress record has orientation_completed = true, set it in profiles
UPDATE profiles p
SET orientation_completed = TRUE
WHERE EXISTS (
  SELECT 1 
  FROM user_progress up
  WHERE up.user_id = p.user_id 
  AND up.orientation_completed = TRUE
);

-- Step 3: Drop orientation_completed column from user_progress
ALTER TABLE user_progress 
DROP COLUMN IF EXISTS orientation_completed;

-- Verification queries
SELECT 'PROFILES TABLE - orientation_completed' as check_name;
SELECT user_id, email, orientation_completed 
FROM profiles 
LIMIT 5;

SELECT 'USER_PROGRESS TABLE - columns' as check_name;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'user_progress'
ORDER BY ordinal_position;
