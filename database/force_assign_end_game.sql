-- ============================================
-- SCRIPT: Force Assign End Game
-- ============================================
-- This script checks if an End Game exists and forces assignment
-- ============================================

DO $$
DECLARE
    v_user_id UUID := '640164ea-3b53-49d3-a9dd-af8632b1e2f6';
    v_end_game_id UUID;
    v_existing_assignment UUID;
BEGIN
    RAISE NOTICE '=== CHECKING END GAME CONFIGURATION ===';
    
    -- 1. Check if there's an active Level 1 End Game
    SELECT id INTO v_end_game_id
    FROM end_game_configs
    WHERE level = 1 AND is_active = TRUE
    LIMIT 1;
    
    IF v_end_game_id IS NULL THEN
        RAISE NOTICE '❌ NO ACTIVE LEVEL 1 END GAME FOUND!';
        RAISE NOTICE 'You need to create an End Game configuration in the admin panel first.';
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

-- Validation Query
SELECT 
    'End Game Assignment Status' as check_type,
    CASE WHEN ega.id IS NOT NULL THEN '✅ ASSIGNED' ELSE '❌ NOT ASSIGNED' END as status,
    ega.id as assignment_id,
    ega.assigned_at
FROM end_game_assignments ega
WHERE ega.user_id = '640164ea-3b53-49d3-a9dd-af8632b1e2f6';
