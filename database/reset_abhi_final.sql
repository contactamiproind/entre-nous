-- FINAL CORRECT RESET for User 'Abhi' (FIXED v2)
-- Corrected 'completed' column to 'completed_at'

DO $$
DECLARE
    target_user_id UUID;
    level1_end_game_id UUID;
BEGIN
    -- 1. Get User ID
    SELECT user_id INTO target_user_id FROM profiles WHERE full_name = 'Abhi';

    -- 2. Get Active Level 1 End Game Config ID
    SELECT id INTO level1_end_game_id 
    FROM end_game_configs 
    WHERE level = 1 AND is_active = true 
    LIMIT 1;

    IF target_user_id IS NOT NULL THEN
        -- A. DELETE EVERYTHING
        DELETE FROM usr_progress WHERE user_id = target_user_id;
        DELETE FROM usr_dept WHERE user_id = target_user_id;
        DELETE FROM end_game_assignments WHERE user_id = target_user_id;
        
        -- B. RESET PROFILE
        UPDATE profiles SET level = 1 WHERE user_id = target_user_id;

        -- C. RE-ASSIGN STANDARD DEPARTMENTS (Fixed dept_name)
        INSERT INTO usr_dept (user_id, dept_id, dept_name, is_current, current_level, completed_levels)
        SELECT 
            target_user_id, 
            id, 
            title, 
            TRUE, -- Set as current
            1,    -- Level 1
            0     -- 0 Completed
        FROM departments 
        WHERE category IN ('Orientation', 'Process', 'SOP');

        -- D. RE-ASSIGN END GAME (Fixed column name)
        IF level1_end_game_id IS NOT NULL THEN
            INSERT INTO end_game_assignments (user_id, end_game_id, assigned_at, score, completed_at)
            VALUES (target_user_id, level1_end_game_id, NOW(), 0, NULL); -- NULL means not completed
            RAISE NOTICE 'Assigned End Game (ID: %) to user', level1_end_game_id;
        ELSE
            RAISE NOTICE 'WARNING: No active Level 1 End Game config found!';
        END IF;

        RAISE NOTICE 'Reset complete for user: %', target_user_id;
    ELSE
        RAISE NOTICE 'User Abhi not found';
    END IF;
END $$;

-- Verify
SELECT * FROM end_game_assignments 
WHERE user_id = (SELECT user_id FROM profiles WHERE full_name = 'Abhi');
