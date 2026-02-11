-- Check current level after End Game completion
SELECT 
    u.email,
    d.category,
    ud.current_level,
    CASE 
        WHEN ud.current_level = 1 THEN 'Level 1'
        WHEN ud.current_level = 2 THEN 'Level 2'
        WHEN ud.current_level = 3 THEN 'Level 3'
        ELSE 'Level ' || ud.current_level::text
    END as level_name
FROM usr_dept ud
JOIN auth.users u ON u.id = ud.user_id
JOIN departments d ON d.id = ud.dept_id
WHERE u.id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6'
ORDER BY d.category;

-- Check End Game completion
SELECT 
    u.email,
    egc.name,
    egc.level,
    ega.completed_at,
    ega.score
FROM end_game_assignments ega
JOIN auth.users u ON u.id = ega.user_id
JOIN end_game_configs egc ON egc.id = ega.end_game_id
WHERE u.id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6';
