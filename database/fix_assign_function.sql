-- ============================================
-- FUNCTION: assign_pathway_with_questions (FIXED)
-- ============================================
-- Assigns a department and all its questions to a user.
-- Updated to use 'level' column instead of 'difficulty'.
-- ============================================

CREATE OR REPLACE FUNCTION assign_pathway_with_questions(
    p_user_id UUID,
    p_dept_id UUID,
    p_assigned_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_usr_dept_id UUID;
    v_dept_name TEXT;
    v_dept_category TEXT;
    v_dept_subcategory TEXT;
    v_total_levels INTEGER;
    v_question_record RECORD;
    v_question_count INTEGER := 0;
BEGIN
    -- Get department details
    SELECT 
        title, 
        category, 
        subcategory, 
        jsonb_array_length(levels)
    INTO 
        v_dept_name, 
        v_dept_category, 
        v_dept_subcategory, 
        v_total_levels
    FROM departments
    WHERE id = p_dept_id;
    
    IF v_dept_name IS NULL THEN
        RAISE EXCEPTION 'Department not found: %', p_dept_id;
    END IF;
    
    -- Check if already assigned
    SELECT id INTO v_usr_dept_id
    FROM usr_dept
    WHERE user_id = p_user_id AND dept_id = p_dept_id;
    
    IF v_usr_dept_id IS NOT NULL THEN
        -- If already assigned, just return the ID (don't error out for auto-assign scenarios)
        RAISE NOTICE 'Department already assigned to this user';
        RETURN v_usr_dept_id;
    END IF;
    
    RAISE NOTICE 'Assigning department: % (ID: %)', v_dept_name, p_dept_id;
    
    -- Create usr_dept record with dept_name
    INSERT INTO usr_dept (
        user_id,
        dept_id,
        dept_name,
        assigned_by,
        total_levels,
        started_at,
        status,
        is_current
    ) VALUES (
        p_user_id,
        p_dept_id,
        v_dept_name,
        p_assigned_by,
        COALESCE(v_total_levels, 0),
        NOW(),
        'active',
        TRUE
    )
    RETURNING id INTO v_usr_dept_id;
    
    RAISE NOTICE 'Created usr_dept record: % with name: %', v_usr_dept_id, v_dept_name;
    
    -- Assign questions from questions table
    -- UPDATED: Use 'level' column instead of 'difficulty'
    FOR v_question_record IN
        SELECT 
            q.id,
            COALESCE(q.title, 'Question') as question_text,
            COALESCE(q.description, '') as question_type,
            -- Map integer level back to difficulty string for display if needed, or just use string representation
            CASE 
                WHEN q.level = 1 THEN 'Easy'
                WHEN q.level = 2 THEN 'Medium'
                WHEN q.level = 3 THEN 'Hard'
                WHEN q.level = 4 THEN 'Expert'
                ELSE 'Easy'
            END as difficulty,
            v_dept_category as category,
            v_dept_subcategory as subcategory,
            COALESCE(q.points, 10) as points,
            q.level as level_number,
            'Level ' || q.level as level_name
        FROM questions q
        WHERE q.dept_id = p_dept_id
    LOOP
        INSERT INTO usr_progress (
            user_id,
            dept_id,
            usr_dept_id,
            question_id,
            question_text,
            question_type,
            difficulty,
            category,
            subcategory,
            points,
            level_number,
            level_name,
            status
        ) VALUES (
            p_user_id,
            p_dept_id,
            v_usr_dept_id,
            v_question_record.id,
            v_question_record.question_text,
            v_question_record.question_type,
            v_question_record.difficulty,
            v_question_record.category,
            v_question_record.subcategory,
            v_question_record.points,
            v_question_record.level_number,
            v_question_record.level_name,
            'pending'
        );
        
        v_question_count := v_question_count + 1;
    END LOOP;
    
    RAISE NOTICE 'Assigned % questions to user', v_question_count;
    
    -- If no questions, generating a warning but not failing
    IF v_question_count = 0 THEN
        RAISE WARNING 'No questions found for department: %. Make sure questions have dept_id set.', p_dept_id;
    END IF;
    
    RETURN v_usr_dept_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT 'assign_pathway_with_questions function updated successfully!' as status;
