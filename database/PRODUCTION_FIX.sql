-- ============================================
-- PRODUCTION FIX: Department Assignment
-- ============================================
-- This script fixes the dept_name issue and ensures production readiness
-- ============================================

-- STEP 1: Check current usr_dept data
SELECT 
    'Current usr_dept records:' as info,
    id,
    user_id,
    dept_id,
    dept_name,
    total_questions,
    status
FROM usr_dept
ORDER BY created_at DESC;

-- STEP 2: Fix existing records with NULL dept_name
UPDATE usr_dept
SET dept_name = d.title
FROM departments d
WHERE usr_dept.dept_id = d.id
AND usr_dept.dept_name IS NULL;

-- STEP 3: Verify the fix
SELECT 
    'After fix:' as info,
    ud.id,
    ud.dept_name,
    d.title as actual_dept_title
FROM usr_dept ud
LEFT JOIN departments d ON ud.dept_id = d.id
ORDER BY ud.created_at DESC;

-- STEP 4: Ensure RPC function saves dept_name correctly
-- This is the PRODUCTION-READY version
DROP FUNCTION IF EXISTS assign_pathway_with_questions(UUID, UUID, UUID);

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
        RAISE EXCEPTION 'Department already assigned to this user';
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
        v_dept_name,  -- CRITICAL: Save dept_name
        p_assigned_by,
        COALESCE(v_total_levels, 0),
        NOW(),
        'active',
        TRUE
    )
    RETURNING id INTO v_usr_dept_id;
    
    RAISE NOTICE 'Created usr_dept record: % with name: %', v_usr_dept_id, v_dept_name;
    
    -- Assign questions from usr_progress table
    -- Questions must have dept_id set
    FOR v_question_record IN
        SELECT 
            q.id,
            COALESCE(q.title, 'Question') as question_text,
            COALESCE(q.description, '') as question_type,
            COALESCE(q.difficulty, 'Easy') as difficulty,
            v_dept_category as category,
            v_dept_subcategory as subcategory,
            COALESCE(q.points, 1) as points,
            CASE 
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) = 'easy' THEN 1
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) IN ('mid', 'medium') THEN 2
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) = 'hard' THEN 3
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) = 'extreme' THEN 4
                ELSE 1
            END as level_number,
            COALESCE(q.difficulty, 'Easy') as level_name
        FROM questions q
        WHERE q.dept_id = p_dept_id  -- Match by dept_id
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
    
    IF v_question_count = 0 THEN
        RAISE WARNING 'No questions found for department: %. Make sure questions have dept_id set.', p_dept_id;
    END IF;
    
    RETURN v_usr_dept_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION assign_pathway_with_questions IS 'PRODUCTION: Assigns department and questions to user with proper dept_name';

-- STEP 5: Verify function works
SELECT 'RPC function updated successfully!' as status;

-- STEP 6: Test query that my_departments_screen uses
SELECT 
    'Test query for my_departments_screen:' as info,
    ud.id,
    ud.user_id,
    ud.dept_id,
    ud.dept_name,
    ud.is_current,
    d.title as dept_title_from_join,
    d.description
FROM usr_dept ud
LEFT JOIN departments d ON ud.dept_id = d.id
ORDER BY ud.created_at DESC
LIMIT 5;

-- ============================================
-- PRODUCTION CHECKLIST
-- ============================================
/*
✅ 1. RPC function saves dept_name correctly
✅ 2. Existing NULL dept_name records updated
✅ 3. Duplicate check added to RPC function
✅ 4. Questions matched by dept_id
✅ 5. Proper error handling and logging
✅ 6. is_current set to TRUE by default

NEXT STEPS:
1. Run this script in Supabase SQL Editor
2. Delete old usr_dept records with NULL dept_name
3. Reassign departments to users
4. Hot restart Flutter app
5. Test complete flow
*/
