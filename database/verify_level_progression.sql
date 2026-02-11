-- ============================================
-- VERIFICATION: Level Progression System
-- ============================================
-- Run these queries to verify the level progression system works
-- ============================================

-- 1. Check if migration was successful
SELECT 
    'Migration Check' as test,
    CASE WHEN COUNT(*) = 2 THEN '✅ COLUMNS EXIST' ELSE '❌ MIGRATION NOT RUN' END as status
FROM information_schema.columns
WHERE table_name = 'end_game_assignments'
AND column_name IN ('completed_at', 'score');

-- 2. View table schema
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'end_game_assignments'
ORDER BY ordinal_position;

-- 3. Check user's current level for all departments
SELECT 
    u.email,
    d.category as department,
    d.difficulty as dept_difficulty,  -- Using 'difficulty' instead of 'level'
    ud.current_level as user_current_level
FROM usr_dept ud
JOIN auth.users u ON u.id = ud.user_id
JOIN departments d ON d.id = ud.dept_id
WHERE u.email LIKE '%abhira%'
ORDER BY u.email, d.category, d.difficulty;

-- 4. Check End Game assignment and completion status
SELECT 
    u.email,
    egc.name as end_game_name,
    egc.level as end_game_level,
    ega.assigned_at,
    ega.completed_at,
    ega.score,
    CASE 
        WHEN ega.completed_at IS NOT NULL THEN '✅ COMPLETED'
        WHEN ega.id IS NOT NULL THEN '⏳ ASSIGNED (Not Completed)'
        ELSE '❌ NOT ASSIGNED'
    END as status
FROM auth.users u
LEFT JOIN end_game_assignments ega ON ega.user_id = u.id
LEFT JOIN end_game_configs egc ON egc.id = ega.end_game_id
WHERE u.email LIKE '%abhira%'
ORDER BY u.email;

-- 5. Check if Level 2 departments exist (using difficulty column)
SELECT 
    'Level 2 Departments' as check,
    category,
    COUNT(*) as count
FROM departments
WHERE difficulty = 2  -- Using 'difficulty' instead of 'level'
GROUP BY category
ORDER BY category;

-- 6. After completing End Game, check if promotion happened
-- Run this AFTER playing and completing the End Game
SELECT 
    u.email,
    d.category,
    d.difficulty as dept_difficulty,  -- Using 'difficulty' instead of 'level'
    ud.current_level,
    CASE 
        WHEN ud.current_level = 2 THEN '✅ PROMOTED TO LEVEL 2'
        WHEN ud.current_level = 1 THEN '⏳ STILL AT LEVEL 1'
        ELSE '❓ UNKNOWN LEVEL'
    END as promotion_status
FROM usr_dept ud
JOIN auth.users u ON u.id = ud.user_id
JOIN departments d ON d.id = ud.dept_id
WHERE u.email LIKE '%abhira%'
ORDER BY d.category;
