-- HARD RESET for User 'Abhi' (FIXED)
-- This will wipe ALL progress and re-assign standard pathways.

DO $$
DECLARE
    target_user_id UUID;
BEGIN
    -- 1. Get User ID
    SELECT user_id INTO target_user_id FROM profiles WHERE full_name = 'Abhi';

    IF target_user_id IS NOT NULL THEN
        -- 2. Delete ALL Progress
        DELETE FROM usr_progress WHERE user_id = target_user_id;

        -- 3. Delete ALL Department Assignments
        DELETE FROM usr_dept WHERE user_id = target_user_id;
        
        -- 4. Delete End Game Assignments
        DELETE FROM end_game_assignments WHERE user_id = target_user_id;

        -- 5. Reset Profile Level
        UPDATE profiles SET level = 1 WHERE user_id = target_user_id;

        -- 6. Re-Assign Standard Pathways (Orientation, Process, SOP, End Game)
        -- FIXED: Included 'dept_name' which is required
        INSERT INTO usr_dept (user_id, dept_id, dept_name, is_current, current_level, completed_levels)
        SELECT 
            target_user_id, 
            id, 
            title, -- Assuming dept_name should be the department title
            TRUE, -- Set as current
            1,    -- Level 1
            0     -- 0 Completed
        FROM departments 
        WHERE category IN ('Orientation', 'Process', 'SOP', 'End Game');

        RAISE NOTICE 'Reset complete for user: %', target_user_id;
    ELSE
        RAISE NOTICE 'User Abhi not found';
    END IF;
END $$;

-- 7. Verify Result
SELECT 
    p.full_name,
    p.level,
    d.category,
    ud.dept_name,
    ud.is_current,
    (SELECT COUNT(*) FROM usr_progress up WHERE up.usr_dept_id = ud.id) as progress_count
FROM profiles p
JOIN usr_dept ud ON p.user_id = ud.user_id
JOIN departments d ON ud.dept_id = d.id
WHERE p.full_name = 'Abhi';
