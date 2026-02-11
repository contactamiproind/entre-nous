-- ============================================
-- Check ALL End Game Assignments
-- ============================================

-- Show all users with End Game assignments
SELECT 
    au.email,
    au.id as user_id,
    ega.id as assignment_id,
    ega.assigned_at,
    egc.name as end_game_name
FROM auth.users au
LEFT JOIN end_game_assignments ega ON ega.user_id = au.id
LEFT JOIN end_game_configs egc ON egc.id = ega.end_game_id
WHERE au.email LIKE '%abhira%'
ORDER BY au.email;
