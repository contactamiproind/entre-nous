-- Set all existing users to level 1
UPDATE profiles 
SET level = 1 
WHERE level IS NULL OR level != 1;

-- Optional: Add a default constraint for new users
ALTER TABLE profiles 
ALTER COLUMN level SET DEFAULT 1;

-- Verify the update
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN level = 1 THEN 1 END) as level_1_users,
  COUNT(CASE WHEN level IS NULL THEN 1 END) as null_level_users
FROM profiles;
