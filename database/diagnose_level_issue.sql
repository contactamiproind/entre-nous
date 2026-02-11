-- Check what happened with the level progression
-- This will show us the current state and help diagnose the issue

-- 1. What level were the departments at BEFORE the End Game?
-- (We can't see this directly, but we can check current state)
SELECT 
    'Current Department Levels' as check_type,
    u.email,
    d.category,
    ud.current_level
FROM usr_dept ud
JOIN auth.users u ON u.id = ud.user_id
JOIN departments d ON d.id = ud.dept_id
WHERE u.id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6'
ORDER BY d.category;

-- 2. What End Game was completed?
SELECT 
    'End Game Completed' as check_type,
    egc.name,
    egc.level as end_game_level,
    ega.completed_at,
    ega.score
FROM end_game_assignments ega
JOIN end_game_configs egc ON egc.id = ega.end_game_id
WHERE ega.user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6'
ORDER BY ega.completed_at DESC;

-- 3. Check if there are multiple department records (duplicates?)
SELECT 
    'Department Assignment Count' as check_type,
    d.category,
    COUNT(*) as assignment_count
FROM usr_dept ud
JOIN departments d ON d.id = ud.dept_id
WHERE ud.user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6'
GROUP BY d.category
HAVING COUNT(*) > 1;
