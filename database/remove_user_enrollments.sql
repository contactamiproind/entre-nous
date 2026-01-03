-- Remove existing pathway enrollment for the user
-- Run this in Supabase SQL Editor

-- Delete user progress
DELETE FROM user_progress
WHERE user_id IN (
  SELECT user_id FROM profiles WHERE email = 'naik.abhira2326@gmail.com'
);

-- Delete user pathway enrollment
DELETE FROM user_pathway
WHERE user_id IN (
  SELECT user_id FROM profiles WHERE email = 'naik.abhira2326@gmail.com'
);

-- Verify deletion
SELECT 'Deleted successfully' as status;
