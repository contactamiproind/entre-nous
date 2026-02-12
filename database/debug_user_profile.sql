-- List all profiles to find the exact name or ID
SELECT user_id, full_name, level 
FROM profiles;

-- Try updating with a wildcard in case there are hidden spaces
-- UPDATE profiles
-- SET level = 2
-- WHERE full_name ILIKE '%Abhi%';
