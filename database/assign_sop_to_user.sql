-- Manually assign SOP to a specific user
-- Replace 'user_email@example.com' with the actual user email

DO $$
DECLARE
    v_user_id UUID;
    v_sop_dept_id UUID;
BEGIN
    -- Get user ID (replace with actual email)
    SELECT user_id INTO v_user_id
    FROM profiles
    WHERE email = 'naik.abhira@gmail.com'; -- CHANGE THIS EMAIL
    
    -- Get SOP department ID
    SELECT id INTO v_sop_dept_id
    FROM departments
    WHERE category = 'SOP'
    LIMIT 1;
    
    -- Check if already assigned
    IF NOT EXISTS (
        SELECT 1 FROM usr_dept
        WHERE user_id = v_user_id AND dept_id = v_sop_dept_id
    ) THEN
        -- Assign SOP with questions
        PERFORM assign_pathway_with_questions(
            p_user_id := v_user_id,
            p_dept_id := v_sop_dept_id,
            p_assigned_by := NULL
        );
        
        RAISE NOTICE 'SOP assigned successfully to user';
    ELSE
        RAISE NOTICE 'SOP already assigned to this user';
    END IF;
END $$;
