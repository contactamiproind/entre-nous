-- Check if user has a profile/progress record with current_pathway_id
SELECT id, user_id, current_pathway_id, current_level
FROM profiles
WHERE user_id = 'fe3c162a-8b43-4a79-b4ff-d32294429781';

-- If current_pathway_id is NULL, update it with the pathway from user_pathway:
-- UPDATE profiles
-- SET current_pathway_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
-- WHERE user_id = 'fe3c162a-8b43-4a79-b4ff-d32294429781';

-- Alternative: Check user_progress table if profiles doesn't have the field
-- SELECT * FROM user_progress WHERE user_id = 'fe3c162a-8b43-4a79-b4ff-d32294429781';
