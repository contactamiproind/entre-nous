-- ============================================
-- Ensure All Users Have All General Departments
-- ============================================
-- This script checks each General department individually
-- and assigns it if the user doesn't have it yet
-- ============================================

DO $$
DECLARE
    v_orientation_id UUID;
    v_process_id UUID;
    v_sop_id UUID;
    v_user RECORD;
    v_assigned_count INTEGER := 0;
BEGIN
    -- Get General department IDs
    SELECT id INTO v_orientation_id 
    FROM departments 
    WHERE title = 'General' AND category = 'Orientation';
    
    SELECT id INTO v_process_id 
    FROM departments 
    WHERE title = 'General' AND category = 'Process';
    
    SELECT id INTO v_sop_id 
    FROM departments 
    WHERE title = 'General' AND category = 'SOP';
    
    -- Check if all General departments exist
    IF v_orientation_id IS NULL OR v_process_id IS NULL OR v_sop_id IS NULL THEN
        RAISE EXCEPTION 'One or more General departments not found. Please run restructure_departments.sql first.';
    END IF;
    
    RAISE NOTICE 'Found General departments:';
    RAISE NOTICE '  Orientation: %', v_orientation_id;
    RAISE NOTICE '  Process: %', v_process_id;
    RAISE NOTICE '  SOP: %', v_sop_id;
    
    -- Loop through all users
    FOR v_user IN 
        SELECT user_id, email
        FROM profiles 
        WHERE role = 'user'
    LOOP
        RAISE NOTICE 'Processing user: %', v_user.email;
        
        -- Check and assign Orientation if missing
        IF NOT EXISTS (
            SELECT 1 FROM usr_dept 
            WHERE user_id = v_user.user_id AND dept_id = v_orientation_id
        ) THEN
            PERFORM assign_pathway_with_questions(v_user.user_id, v_orientation_id, NULL);
            RAISE NOTICE '  ✓ Assigned Orientation to %', v_user.email;
            v_assigned_count := v_assigned_count + 1;
        ELSE
            RAISE NOTICE '  - Orientation already assigned to %', v_user.email;
        END IF;
        
        -- Check and assign Process if missing
        IF NOT EXISTS (
            SELECT 1 FROM usr_dept 
            WHERE user_id = v_user.user_id AND dept_id = v_process_id
        ) THEN
            PERFORM assign_pathway_with_questions(v_user.user_id, v_process_id, NULL);
            RAISE NOTICE '  ✓ Assigned Process to %', v_user.email;
            v_assigned_count := v_assigned_count + 1;
        ELSE
            RAISE NOTICE '  - Process already assigned to %', v_user.email;
        END IF;
        
        -- Check and assign SOP if missing
        IF NOT EXISTS (
            SELECT 1 FROM usr_dept 
            WHERE user_id = v_user.user_id AND dept_id = v_sop_id
        ) THEN
            PERFORM assign_pathway_with_questions(v_user.user_id, v_sop_id, NULL);
            RAISE NOTICE '  ✓ Assigned SOP to %', v_user.email;
            v_assigned_count := v_assigned_count + 1;
        ELSE
            RAISE NOTICE '  - SOP already assigned to %', v_user.email;
        END IF;
    END LOOP;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration complete! Made % new assignments.', v_assigned_count;
    RAISE NOTICE '========================================';
END $$;

-- Verify the assignments
SELECT 
    p.email,
    d.category,
    ud.id as usr_dept_id
FROM profiles p
LEFT JOIN usr_dept ud ON p.user_id = ud.user_id
LEFT JOIN departments d ON ud.dept_id = d.id
WHERE p.role = 'user' AND d.title = 'General'
ORDER BY p.email, d.category;

SELECT 'All users now have General departments assigned!' as status;
