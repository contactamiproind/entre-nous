-- ============================================
-- Test RLS Policies for End Game Assignments
-- ============================================
-- This checks if the user can read their own assignment
-- ============================================

-- 1. Check RLS policies on end_game_assignments
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'end_game_assignments';

-- 2. Try to query as if you were the user (simulated)
-- This shows what the actual user would see
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '0:0:0:0:0:0:0:1';

SELECT 
    'User Query Simulation' as test,
    id,
    user_id,
    end_game_id,
    assigned_at
FROM end_game_assignments
WHERE user_id = '0:0:0:0:0:0:0:1';

RESET ROLE;
