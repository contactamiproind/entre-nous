-- Find the correct user ID by email
SELECT id, email, created_at
FROM auth.users
WHERE email = 'naik.abhira2326@gmail.com';

-- Once you have the correct ID, use it to insert into user_progress
-- Replace YOUR_ACTUAL_USER_ID with the ID from the query above
/*
INSERT INTO user_progress (user_id, current_pathway_id, current_level)
VALUES ('YOUR_ACTUAL_USER_ID', '32d2764f-ed76-40db-8886-bcf5923f91a1', 1)
ON CONFLICT (user_id) DO UPDATE 
SET current_pathway_id = EXCLUDED.current_pathway_id;
*/
