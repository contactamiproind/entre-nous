-- ============================================
-- RESET USER TO LEVEL 1 FOR PROPER TESTING
-- ============================================
-- This will reset the user back to Level 1 and clear End Game completion
-- so you can test the Level 1 → Level 2 progression properly
-- ============================================

-- 1. Reset all departments to Level 1
UPDATE usr_dept
SET current_level = 1
WHERE user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6';

-- 2. Clear End Game completion (keep assignment but reset completion)
UPDATE end_game_assignments
SET completed_at = NULL,
    score = 0
WHERE user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6';

-- 3. Verify the reset
SELECT 
    '✅ Reset Complete' as status,
    'All departments reset to Level 1' as message;

-- 4. Show current state
SELECT 
    'Current State' as check_type,
    d.category,
    ud.current_level
FROM usr_dept ud
JOIN departments d ON d.id = ud.dept_id
WHERE ud.user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6'
ORDER BY d.category;

-- 5. Show End Game status
SELECT 
    'End Game Status' as check_type,
    egc.name,
    egc.level,
    ega.completed_at,
    ega.score,
    CASE 
        WHEN ega.completed_at IS NULL THEN '⏳ Ready to test (not completed)'
        ELSE '✅ Completed'
    END as status
FROM end_game_assignments ega
JOIN end_game_configs egc ON egc.id = ega.end_game_id
WHERE ega.user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6';
