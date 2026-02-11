-- ============================================
-- SCRIPT: Fix User Assignments by UUID
-- ============================================
-- Usage: Run this script directly.
-- This script will:
-- 1. Auto-assign General Departments (Orientation, Process, SOP) if missing.
-- 2. Auto-assign End Game if eligible.
-- ============================================

DO $$
DECLARE
    -- REPLACE THIS WITH YOUR USER ID IF DIFFERENT
    v_user_id UUID := '640164ea-3b53-49d3-a9dd-af8632b1e2f6'; 
    v_user_exists BOOLEAN;
BEGIN
    RAISE NOTICE '✅ Fixing User ID: %', v_user_id;

    -- 1. Ensure General Departments are Assigned
    -- This function checks if user has 0 departments, then assigns General ones.
    -- If user already has some other departments (but not General), this specific function skips.
    -- So let's force check and assign manually just in case.
    
    PERFORM auto_assign_general_departments(v_user_id);
    RAISE NOTICE '🔄 Ran auto-assign logic for General Departments.';

    -- 2. Check and Assign End Game
    -- This uses the function we created earlier
    PERFORM check_and_assign_end_game(v_user_id);
    RAISE NOTICE '🔄 Ran check-and-assign for End Game.';

END $$;

-- Validation Query to run AFTER the block above
SELECT 
    d.title as department,
    d.category,
    ud.current_level,
    CASE WHEN ega.id IS NOT NULL THEN 'ASSIGNED' ELSE 'NOT ASSIGNED' END as end_game_status
FROM usr_dept ud
LEFT JOIN departments d ON d.id = ud.dept_id
LEFT JOIN end_game_assignments ega ON ega.user_id = ud.user_id
WHERE ud.user_id = '640164ea-3b53-49d3-a9dd-af8632b1e2f6';
