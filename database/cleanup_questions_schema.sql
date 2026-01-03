-- ============================================
-- Cleanup: Remove Redundant Columns from Questions
-- ============================================
-- Remove: orientation_id, category, subcategory (redundant)
-- Keep: dept_id (links to departments table which has category/subcategory)
-- ============================================

-- Step 1: Verify current structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'questions'
AND column_name IN ('orientation_id', 'category', 'subcategory', 'dept_id')
ORDER BY ordinal_position;

-- Step 2: Drop redundant columns
ALTER TABLE questions DROP COLUMN IF EXISTS orientation_id;
ALTER TABLE questions DROP COLUMN IF EXISTS category;
ALTER TABLE questions DROP COLUMN IF EXISTS subcategory;

-- Step 3: Ensure dept_id exists and has proper constraint
-- If dept_id doesn't exist, create it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'questions' AND column_name = 'dept_id'
    ) THEN
        ALTER TABLE questions ADD COLUMN dept_id UUID REFERENCES departments(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added dept_id column to questions table';
    END IF;
END $$;

-- Step 4: Add index on dept_id for performance
CREATE INDEX IF NOT EXISTS idx_questions_dept_id ON questions(dept_id);

-- Step 5: Update RPC function to use dept_id instead of category matching
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
    
    -- SIMPLIFIED: Match questions by dept_id (no more category matching!)
    FOR v_question_record IN
        SELECT 
            q.id,
            COALESCE(q.title, 'Question') as question_text,
            COALESCE(q.description, '') as question_type,
            COALESCE(q.difficulty, 'Easy') as difficulty,
            d.category,  -- Get from departments table
            d.subcategory,  -- Get from departments table
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
        INNER JOIN departments d ON q.dept_id = d.id
        WHERE q.dept_id = p_dept_id  -- Simple and clean!
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
        RAISE WARNING 'No questions found for department: %', p_dept_id;
    END IF;
    
    RETURN v_usr_dept_id;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Verify the cleanup
SELECT 'Schema cleanup completed!' as status;
SELECT 'Questions now link to departments via dept_id' as note;

-- Step 7: Check updated structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'questions'
ORDER BY ordinal_position;

-- ============================================
-- IMPORTANT: Update Your Questions
-- ============================================
-- Now you need to set dept_id for your questions
-- Example:
/*
-- Get department IDs
SELECT id, title FROM departments ORDER BY title;

-- Assign questions to a department
UPDATE questions 
SET dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'  -- Replace with actual dept_id
WHERE id IN (
    -- Your question IDs
    'question-uuid-1',
    'question-uuid-2'
);
*/
