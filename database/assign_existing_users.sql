-- ============================================
-- Assign General Departments to Existing Users
-- ============================================
-- This script assigns Orientation, Process, and SOP
-- to all existing users who don't have any departments yet
-- ============================================

DO $$
DECLARE
    v_orientation_id UUID;
    v_process_id UUID;
    v_sop_id UUID;
    v_user RECORD;
    v_dept_count INTEGER;
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
    
    -- Loop through all users
    FOR v_user IN 
        SELECT user_id 
        FROM profiles 
        WHERE role = 'user'
    LOOP
        -- Check if user already has departments assigned
        SELECT COUNT(*) INTO v_dept_count
        FROM usr_dept
        WHERE user_id = v_user.user_id;
        
        -- Only assign if user has no departments
        IF v_dept_count = 0 THEN
            -- Assign Orientation
            PERFORM assign_pathway_with_questions(v_user.user_id, v_orientation_id, NULL);
            
            -- Assign Process
            PERFORM assign_pathway_with_questions(v_user.user_id, v_process_id, NULL);
            
            -- Assign SOP
            PERFORM assign_pathway_with_questions(v_user.user_id, v_sop_id, NULL);
            
            v_assigned_count := v_assigned_count + 1;
            
            RAISE NOTICE 'Assigned General departments to user: %', v_user.user_id;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Migration complete! Assigned General departments to % users.', v_assigned_count;
END $$;

-- Verify the assignments
SELECT 
    p.email,
    COUNT(DISTINCT ud.dept_id) as assigned_departments
FROM profiles p
LEFT JOIN usr_dept ud ON p.user_id = ud.user_id
WHERE p.role = 'user'
GROUP BY p.email
ORDER BY assigned_departments DESC;

SELECT 'Existing users migration complete!' as status;
