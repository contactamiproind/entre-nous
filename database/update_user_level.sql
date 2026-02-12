-- Update User Level to 2
-- Run this to force the level update.

-- OPTION 1: Update by Name (since we saw 'Abhi' in the screenshot)
UPDATE profiles
SET level = 2
WHERE full_name = 'Abhi';

-- OPTION 2: Update by User ID (from your screenshot)
-- UPDATE profiles
-- SET level = 2
-- WHERE user_id = '643164ea-3b53-49d3-a9dd-ef8632b1e2f6';

-- OPTION 3: Update for currently logged in user (if running in App context)
-- UPDATE profiles
-- SET level = 2
-- WHERE user_id = auth.uid();

-- Verify the change
SELECT full_name, level FROM profiles WHERE full_name = 'Abhi';
