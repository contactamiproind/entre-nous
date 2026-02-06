-- ============================================
-- Auto-assign General Departments Function (UPDATED)
-- ============================================
-- This function automatically assigns the 3 General departments
-- (Orientation, Process, SOP) to a user.
-- It checks each department individually and assigns if missing.
-- ============================================

CREATE OR REPLACE FUNCTION auto_assign_general_departments(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_orientation_id UUID;
    v_process_id UUID;
    v_sop_id UUID;
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
    
    -- Assign Orientation if not already assigned
    IF v_orientation_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM usr_dept WHERE user_id = p_user_id AND dept_id = v_orientation_id
    ) THEN
        PERFORM assign_pathway_with_questions(p_user_id, v_orientation_id, NULL);
        RAISE NOTICE 'Assigned Orientation to user %', p_user_id;
    END IF;
    
    -- Assign Process if not already assigned
    IF v_process_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM usr_dept WHERE user_id = p_user_id AND dept_id = v_process_id
    ) THEN
        PERFORM assign_pathway_with_questions(p_user_id, v_process_id, NULL);
        RAISE NOTICE 'Assigned Process to user %', p_user_id;
    END IF;
    
    -- Assign SOP if not already assigned
    IF v_sop_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM usr_dept WHERE user_id = p_user_id AND dept_id = v_sop_id
    ) THEN
        PERFORM assign_pathway_with_questions(p_user_id, v_sop_id, NULL);
        RAISE NOTICE 'Assigned SOP to user %', p_user_id;
    END IF;
    
    RAISE NOTICE 'Auto-assignment check complete for user %', p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION auto_assign_general_departments(UUID) TO authenticated;

SELECT 'auto_assign_general_departments function updated successfully!' as status;
