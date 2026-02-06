-- ============================================
-- Auto-assign General Departments Function
-- ============================================
-- This function automatically assigns the 3 General departments
-- (Orientation, Process, SOP) to a new user on first login
-- ============================================

CREATE OR REPLACE FUNCTION auto_assign_general_departments(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_orientation_id UUID;
    v_process_id UUID;
    v_sop_id UUID;
    v_existing_count INTEGER;
BEGIN
    -- Check if user already has departments assigned
    SELECT COUNT(*) INTO v_existing_count
    FROM usr_dept
    WHERE user_id = p_user_id;
    
    -- Only assign if user has no departments yet (first login)
    IF v_existing_count = 0 THEN
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
        
        -- Assign Orientation (if exists)
        IF v_orientation_id IS NOT NULL THEN
            PERFORM assign_pathway_with_questions(p_user_id, v_orientation_id, NULL);
        END IF;
        
        -- Assign Process (if exists)
        IF v_process_id IS NOT NULL THEN
            PERFORM assign_pathway_with_questions(p_user_id, v_process_id, NULL);
        END IF;
        
        -- Assign SOP (if exists)
        IF v_sop_id IS NOT NULL THEN
            PERFORM assign_pathway_with_questions(p_user_id, v_sop_id, NULL);
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION auto_assign_general_departments(UUID) TO authenticated;

SELECT 'auto_assign_general_departments function created successfully!' as status;
