-- ============================================
-- REMOVE DUPLICATE DEPARTMENTS (FIXED)
-- ============================================
-- Handles foreign key constraints properly

-- ============================================
-- STEP 1: Get the Mandatory Orientation ID
-- ============================================

DO $$
DECLARE
    mandatory_orientation_id UUID;
    old_orientation_id UUID;
    sales_id UUID;
BEGIN
    -- Get the IDs
    SELECT id INTO mandatory_orientation_id FROM departments WHERE title = 'Orientation' AND category = 'Mandatory';
    SELECT id INTO old_orientation_id FROM departments WHERE title = 'Orientation' AND category = 'Onboarding';
    SELECT id INTO sales_id FROM departments WHERE title = 'Sales';
    
    RAISE NOTICE 'Mandatory Orientation ID: %', mandatory_orientation_id;
    RAISE NOTICE 'Old Orientation ID: %', old_orientation_id;
    RAISE NOTICE 'Sales ID: %', sales_id;
    
    -- Update questions to point to Mandatory Orientation (if you want to keep them)
    -- OR delete them (if you want fresh start)
    
    -- Option 1: Update questions to new department
    IF old_orientation_id IS NOT NULL AND mandatory_orientation_id IS NOT NULL THEN
        UPDATE questions 
        SET dept_id = mandatory_orientation_id,
            orientation_id = mandatory_orientation_id
        WHERE dept_id = old_orientation_id;
        
        RAISE NOTICE 'Updated questions from old Orientation to Mandatory Orientation';
    END IF;
    
    -- Option 2: Delete Sales questions
    IF sales_id IS NOT NULL THEN
        DELETE FROM questions WHERE dept_id = sales_id;
        RAISE NOTICE 'Deleted Sales questions';
    END IF;
    
    -- Now safe to delete departments
    IF old_orientation_id IS NOT NULL THEN
        DELETE FROM departments WHERE id = old_orientation_id;
        RAISE NOTICE 'Deleted old Orientation department';
    END IF;
    
    IF sales_id IS NOT NULL THEN
        DELETE FROM departments WHERE id = sales_id;
        RAISE NOTICE 'Deleted Sales department';
    END IF;
END $$;

-- ============================================
-- STEP 2: Verify only Mandatory Orientation remains
-- ============================================

SELECT 
    id,
    title,
    category,
    description
FROM departments;

-- ============================================
-- STEP 3: Verify dept_levels
-- ============================================

SELECT 
    d.title as department,
    d.category,
    dl.level_number,
    dl.title as level_name
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
ORDER BY d.title, dl.level_number;

-- ============================================
-- STEP 4: Count questions
-- ============================================

SELECT 
    d.title as department,
    COUNT(q.id) as question_count
FROM departments d
LEFT JOIN questions q ON d.id = q.dept_id
GROUP BY d.title;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Cleanup Complete!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Database now has:';
    RAISE NOTICE '  ✅ 1 Department: Orientation (Mandatory)';
    RAISE NOTICE '  ✅ 4 Levels: Easy, Mid, Hard, Extreme';
END $$;
