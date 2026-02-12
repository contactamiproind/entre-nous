-- Reset User 'Abhi' to Level 1 for testing transition

-- 1. Reset Profile Level to 1
UPDATE profiles
SET level = 1
WHERE full_name = 'Abhi';

-- 2. Clear End Game Assignments (so it can be completed again)
DELETE FROM end_game_assignments
WHERE user_id IN (SELECT user_id FROM profiles WHERE full_name = 'Abhi');

-- 3. Clear User Progress for End Game (optional, but good for clean test)
-- Note: This requires knowing the dept_id for 'End Game' or joining
DELETE FROM usr_progress
WHERE user_id IN (SELECT user_id FROM profiles WHERE full_name = 'Abhi')
  AND dept_id IN (SELECT id FROM departments WHERE category = 'End Game');

-- 4. Verify result
SELECT full_name, level FROM profiles WHERE full_name = 'Abhi';
