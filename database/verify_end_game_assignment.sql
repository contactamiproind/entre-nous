-- ============================================
-- VERIFICATION: Check End Game Assignment Status
-- ============================================
-- Run this to verify the End Game assignment exists
-- ============================================

-- 1. Check if End Game assignment exists
SELECT 
    'Assignment Check' as test,
    CASE WHEN COUNT(*) > 0 THEN '✅ ASSIGNED' ELSE '❌ NOT ASSIGNED' END as status,
    COUNT(*) as assignment_count
FROM end_game_assignments
WHERE user_id = '640164ea-3b53-49d3-a9dd-af8632b1e2f6';

-- 2. Get full assignment details
SELECT 
    ega.id as assignment_id,
    ega.user_id,
    ega.end_game_id,
    ega.assigned_at,
    egc.name as end_game_name,
    egc.level as end_game_level,
    egc.is_active
FROM end_game_assignments ega
JOIN end_game_configs egc ON egc.id = ega.end_game_id
WHERE ega.user_id = '640164ea-3b53-49d3-a9dd-af8632b1e2f6';

-- 3. Check what the dashboard query would return
SELECT 
    'Dashboard Query Simulation' as test,
    id,
    end_game_id,
    assigned_at
FROM end_game_assignments
WHERE user_id = '640164ea-3b53-49d3-a9dd-af8632b1e2f6';
