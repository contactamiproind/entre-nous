-- ============================================
-- Assign End Game to abhira2326@gmail.com
-- ============================================

DO $$
DECLARE
    v_user_id UUID := '8c5b4f39-1d88-4268-b2b1-e9c0b3838b5c'; -- abhira2326@gmail.com
    v_end_game_id UUID;
    v_existing_assignment UUID;
BEGIN
    RAISE NOTICE '=== ASSIGNING END GAME TO abhira2326@gmail.com ===';
    
    -- 1. Check if there's an active Level 1 End Game
    SELECT id INTO v_end_game_id
    FROM end_game_configs
    WHERE level = 1 AND is_active = TRUE
    LIMIT 1;
    
    IF v_end_game_id IS NULL THEN
        RAISE NOTICE '❌ NO ACTIVE LEVEL 1 END GAME FOUND!';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Found End Game ID: %', v_end_game_id;
    
    -- 2. Check if already assigned
    SELECT id INTO v_existing_assignment
    FROM end_game_assignments
    WHERE user_id = v_user_id AND end_game_id = v_end_game_id;
    
    IF v_existing_assignment IS NOT NULL THEN
        RAISE NOTICE '✅ End Game already assigned (ID: %)', v_existing_assignment;
        RETURN;
    END IF;
    
    -- 3. Force assign
    INSERT INTO end_game_assignments (user_id, end_game_id)
    VALUES (v_user_id, v_end_game_id)
    RETURNING id INTO v_existing_assignment;
    
    RAISE NOTICE '🎉 SUCCESSFULLY ASSIGNED END GAME (Assignment ID: %)', v_existing_assignment;
    
END $$;

-- Validation
SELECT 
    'abhira2326@gmail.com End Game Status' as check,
    CASE WHEN ega.id IS NOT NULL THEN '✅ ASSIGNED' ELSE '❌ NOT ASSIGNED' END as status
FROM auth.users au
LEFT JOIN end_game_assignments ega ON ega.user_id = au.id
WHERE au.email = 'abhira2326@gmail.com';
