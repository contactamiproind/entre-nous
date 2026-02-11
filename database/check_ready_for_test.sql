-- ============================================
-- QUICK CHECK: Ready for Level Progression Test?
-- ============================================

-- 1. Migration Status
SELECT 
    'Migration Check' as test,
    CASE WHEN COUNT(*) = 2 THEN '✅ COLUMNS EXIST' ELSE '❌ MIGRATION NOT RUN' END as status
FROM information_schema.columns
WHERE table_name = 'end_game_assignments'
AND column_name IN ('completed_at', 'score');

-- 2. End Game Assignment Status
SELECT 
    u.email,
    egc.name as end_game_name,
    egc.level as end_game_level,
    ega.assigned_at,
    ega.completed_at,
    ega.score,
    CASE 
        WHEN ega.completed_at IS NOT NULL THEN '✅ COMPLETED (Ready to test promotion again)'
        WHEN ega.id IS NOT NULL THEN '⏳ ASSIGNED (Play and complete to test promotion)'
        ELSE '❌ NOT ASSIGNED (Need to assign first)'
    END as status
FROM auth.users u
LEFT JOIN end_game_assignments ega ON ega.user_id = u.id
LEFT JOIN end_game_configs egc ON egc.id = ega.end_game_id
WHERE u.email LIKE '%abhira%'
ORDER BY u.email;

-- 3. Current Level Status
SELECT 
    u.email,
    COUNT(DISTINCT d.category) as total_departments,
    COUNT(DISTINCT CASE WHEN ud.current_level = 1 THEN d.category END) as level_1_depts,
    COUNT(DISTINCT CASE WHEN ud.current_level = 2 THEN d.category END) as level_2_depts,
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN ud.current_level = 2 THEN d.category END) > 0 
        THEN '✅ ALREADY PROMOTED TO LEVEL 2'
        ELSE '⏳ STILL AT LEVEL 1 (Complete End Game to promote)'
    END as overall_status
FROM usr_dept ud
JOIN auth.users u ON u.id = ud.user_id
JOIN departments d ON d.id = ud.dept_id
WHERE u.email LIKE '%abhira%'
GROUP BY u.email;

-- 4. Next Steps
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM end_game_assignments ega
            JOIN auth.users u ON u.id = ega.user_id
            WHERE u.email LIKE '%abhira%' AND ega.completed_at IS NOT NULL
        ) THEN '🔄 End Game already completed. To test again: 1) Reset completion in DB, 2) Play End Game, 3) Check for promotion'
        WHEN EXISTS (
            SELECT 1 FROM end_game_assignments ega
            JOIN auth.users u ON u.id = ega.user_id
            WHERE u.email LIKE '%abhira%' AND ega.id IS NOT NULL
        ) THEN '🎮 READY TO TEST! 1) Restart app, 2) Play and complete End Game, 3) Watch console for "🎉 PROMOTED" message'
        ELSE '⚠️ End Game not assigned. Run auto_assign_end_game.sql first'
    END as next_action;
