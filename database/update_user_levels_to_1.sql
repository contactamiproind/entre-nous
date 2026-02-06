-- Add level column to profiles table if it doesn't exist
-- This script is safe to run multiple times

-- Step 1: Add level column to profiles table
DO $$ 
BEGIN
  -- Try to add the column
  ALTER TABLE profiles ADD COLUMN level INTEGER DEFAULT 1;
EXCEPTION
  -- If column already exists, just ignore the error
  WHEN duplicate_column THEN NULL;
END $$;

-- Step 2: Set all existing users to level 1 (in case some are NULL)
UPDATE profiles 
SET level = 1 
WHERE level IS NULL;

-- Step 3: Ensure default is set
ALTER TABLE profiles 
ALTER COLUMN level SET DEFAULT 1;

-- Step 4: Add constraint to ensure level is between 1 and 4
DO $$ 
BEGIN
  ALTER TABLE profiles 
  ADD CONSTRAINT profiles_level_range CHECK (level >= 1 AND level <= 4);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Step 5: Ensure questions table has proper constraint (if not already set)
DO $$ 
BEGIN
  ALTER TABLE questions 
  ADD CONSTRAINT questions_level_range CHECK (level >= 1 AND level <= 4);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Verification queries
SELECT 'Questions by level:' as info;
SELECT level, COUNT(*) as count FROM questions GROUP BY level ORDER BY level;

SELECT 'Users by level:' as info;
SELECT level, COUNT(*) as count FROM profiles GROUP BY level ORDER BY level;
