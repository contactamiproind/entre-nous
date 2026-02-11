-- Reset user to Level 1 and clear End Game completion for testing
-- This allows you to test the Level 1 → Level 2 promotion again

-- 1. Reset all departments to Level 1
UPDATE usr_dept
SET current_level = 1
WHERE user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6';

-- 2. Clear End Game completion
UPDATE end_game_assignments
SET completed_at = NULL,
    score = NULL
WHERE user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6';

-- 3. Verify the reset
SELECT 
    'User Departments' as check_type,
    d.category_name,
    ud.current_level
FROM usr_dept ud
JOIN departments d ON d.id = ud.dept_id
WHERE ud.user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6'
ORDER BY d.category_name;

SELECT 
    'End Game Status' as check_type,
    completed_at,
    score,
    assigned_at
FROM end_game_assignments
WHERE user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6';
