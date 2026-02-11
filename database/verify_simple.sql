-- ============================================
-- SIMPLIFIED VERIFICATION (No assumptions about column names)
-- ============================================

-- 1. Check migration success
SELECT 
    'Migration Check' as test,
    CASE WHEN COUNT(*) = 2 THEN '✅ COLUMNS EXIST' ELSE '❌ MIGRATION NOT RUN' END as status
FROM information_schema.columns
WHERE table_name = 'end_game_assignments'
AND column_name IN ('completed_at', 'score');

-- 2. Check departments table schema
SELECT 
    'Departments Table Schema' as info,
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_name = 'departments'
ORDER BY ordinal_position;

-- 3. Check user's current level (simplified - no dept level)
SELECT 
    u.email,
    d.category as department,
    d.id as dept_id,
    ud.current_level as user_current_level
FROM usr_dept ud
JOIN auth.users u ON u.id = ud.user_id
JOIN departments d ON d.id = ud.dept_id
WHERE u.email LIKE '%abhira%'
ORDER BY u.email, d.category;

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

-- 5. Check all departments (to see what categories exist)
SELECT 
    category,
    COUNT(*) as count
FROM departments
GROUP BY category
ORDER BY category;

-- 6. Check promotion status (simplified)
SELECT 
    u.email,
    d.category,
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
