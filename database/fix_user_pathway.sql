-- Query to check user pathway assignment
-- Replace YOUR_USER_ID with the actual user ID (without extra quotes!)

SELECT id, user_id, pathway_id, pathway_name
FROM user_pathway
WHERE user_id = 'e3c162a-8b43-4a79-b4ff-d32294429781';

-- If pathway_id is NULL, you need to update it:
-- First, get a valid pathway ID from departments table:
-- SELECT id, title FROM departments LIMIT 5;

-- Then update the user_pathway record:
-- UPDATE user_pathway 
-- SET pathway_id = 'PASTE_PATHWAY_ID_HERE'
-- WHERE user_id = 'e3c162a-8b43-4a79-b4ff-d32294429781';
