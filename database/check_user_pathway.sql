-- Check user_pathway records and their dept_id values
SELECT 
    up.id,
    up.user_id,
    up.dept_id,
    up.assigned_at,
    d.title as department_title
FROM user_pathway up
LEFT JOIN departments d ON up.dept_id = d.id
ORDER BY up.assigned_at DESC
LIMIT 10;

-- If dept_id is NULL, you can update it based on the user's profile or manually:
-- UPDATE user_pathway 
-- SET dept_id = 'YOUR_DEPARTMENT_ID_HERE'
-- WHERE user_id = 'YOUR_USER_ID_HERE' AND dept_id IS NULL;
