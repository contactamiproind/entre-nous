-- ============================================
-- Fix: Questions Have NULL Categories
-- ============================================
-- Problem: All 5 questions have NULL category, so they can't match departments
-- Solution: Either update questions OR change matching logic
-- ============================================

-- OPTION 1: Update questions to have categories (RECOMMENDED)
-- ============================================
-- First, see what departments you have:
SELECT id, title, category, subcategory FROM departments ORDER BY title;

-- Then update questions to match a department category
-- Example: If you have "Orientation" department, update questions:
/*
UPDATE questions 
SET category = 'Orientation', 
    subcategory = 'Vision'
WHERE id IN (
    -- List your question IDs here
    'question-uuid-1',
    'question-uuid-2'
);
*/

-- OPTION 2: Change RPC function to assign ALL questions (QUICK FIX)
-- ============================================
-- This will assign ALL questions regardless of category

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
    SELECT title, category, subcategory, jsonb_array_length(levels)
    INTO v_dept_name, v_dept_category, v_dept_subcategory, v_total_levels
    FROM departments
    WHERE id = p_dept_id;
    
    IF v_dept_name IS NULL THEN
        RAISE EXCEPTION 'Department not found: %', p_dept_id;
    END IF;
    
    RAISE NOTICE 'Assigning department: % (category: %)', v_dept_name, v_dept_category;
    
    -- Create usr_dept record
    INSERT INTO usr_dept (
        user_id,
        dept_id,
        dept_name,
        assigned_by,
        total_levels,
        started_at,
        status
    ) VALUES (
        p_user_id,
        p_dept_id,
        v_dept_name,
        p_assigned_by,
        COALESCE(v_total_levels, 0),
        NOW(),
        'active'
    )
    RETURNING id INTO v_usr_dept_id;
    
    -- CHANGED: Assign ALL questions (since questions have NULL category)
    -- Later you can filter by category once questions are properly categorized
    FOR v_question_record IN
        SELECT 
            q.id,
            COALESCE(q.title, 'Question') as question_text,
            COALESCE(q.description, '') as question_type,
            COALESCE(q.difficulty, 'Easy') as difficulty,
            q.category,
            q.subcategory,
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
        -- REMOVED category filter since all questions have NULL category
        -- WHERE q.category = v_dept_category
        -- Once you add categories to questions, uncomment the WHERE clause
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
        RAISE WARNING 'No questions found in database!';
    END IF;
    
    RETURN v_usr_dept_id;
END;
$$ LANGUAGE plpgsql;

-- Test it
SELECT 'Function updated to assign ALL questions (temporary fix)' as status;

-- ============================================
-- RECOMMENDED: Properly categorize your questions
-- ============================================
-- After running the function above, you should:
-- 1. Add categories to your questions
-- 2. Update the function to filter by category again
-- 3. This ensures users only get relevant questions for their department
