-- ============================================
-- SCRIPT: Fix User Assignments by Email
-- ============================================
-- Usage: Replace 'your_email@example.com' with the actual user email.
-- This script will:
-- 1. Find the user by email.
-- 2. Auto-assign General Departments (Orientation, Process, SOP) if missing.
-- 3. Auto-assign End Game if eligible.
-- ============================================

DO $$
DECLARE
    v_user_email TEXT := 'abhira.naik@andorbitsolutions.com'; -- REPLACE THIS WITH YOUR EMAIL
    v_user_id UUID;
    v_user_exists BOOLEAN;
BEGIN
    -- 1. Get User ID
    SELECT id INTO v_user_id FROM auth.users WHERE email = v_user_email;
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE '❌ User not found with email: %', v_user_email;
        RETURN;
    END IF;

    RAISE NOTICE '✅ Found User ID: %', v_user_id;

    -- 2. Ensure General Departments are Assigned
    -- verify if auto_assign_general_departments exists first
    PERFORM auto_assign_general_departments(v_user_id);
    RAISE NOTICE '🔄 Ran auto-assign for General Departments.';

    -- 3. Check and Assign End Game
    -- This uses the function we created earlier
    PERFORM check_and_assign_end_game(v_user_id);
    RAISE NOTICE '🔄 Ran check-and-assign for End Game.';

    -- 4. Final Status Report
    RAISE NOTICE '--- FINAL STATUS ---';
    
    -- List Departments
    FOR v_user_exists IN 
        SELECT TRUE FROM usr_dept WHERE user_id = v_user_id
    LOOP
        -- just a dummy loop to print
    END LOOP;

END $$;

-- Validation Query to run AFTER the block above
SELECT 
    u.email,
    d.title as department,
    d.category,
    ud.current_level,
    CASE WHEN ega.id IS NOT NULL THEN 'ASSIGNED' ELSE 'NOT ASSIGNED' END as end_game_status
FROM auth.users u
LEFT JOIN usr_dept ud ON ud.user_id = u.id
LEFT JOIN departments d ON d.id = ud.dept_id
LEFT JOIN end_game_assignments ega ON ega.user_id = u.id
WHERE u.email = 'abhira.naik@andorbitsolutions.com'; -- REPLACE THIS WITH YOUR EMAIL
