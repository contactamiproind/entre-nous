-- ============================================
-- CLEAN SLATE: DELETE ALL LEVELS AND RECREATE
-- ============================================
-- This ensures exactly 4 levels per department

-- ============================================
-- STEP 1: Delete ALL existing levels
-- ============================================

DELETE FROM dept_levels;

-- ============================================
-- STEP 2: Recreate levels for each department
-- ============================================

DO $$
DECLARE
    dept_record RECORD;
BEGIN
    -- Loop through all departments
    FOR dept_record IN 
        SELECT id, title FROM departments
    LOOP
        -- Insert exactly 4 levels for each department
        INSERT INTO dept_levels (dept_id, level_id, title, category, level_number)
        VALUES 
            (dept_record.id, gen_random_uuid(), 'Easy', 'Beginner', 1),
            (dept_record.id, gen_random_uuid(), 'Mid', 'Intermediate', 2),
            (dept_record.id, gen_random_uuid(), 'Hard', 'Advanced', 3),
            (dept_record.id, gen_random_uuid(), 'Extreme', 'Expert', 4);
        
        RAISE NOTICE 'Created 4 levels for: %', dept_record.title;
    END LOOP;
END $$;

-- ============================================
-- STEP 3: Verify - Each department has 4 levels
-- ============================================

SELECT 
    d.title as department,
    dl.level_number,
    dl.title as level_name,
    dl.category
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
ORDER BY d.title, dl.level_number;

-- ============================================
-- STEP 4: Count levels per department
-- ============================================

SELECT 
    d.title as department,
    COUNT(dl.id) as level_count
FROM departments d
LEFT JOIN dept_levels dl ON d.id = dl.dept_id
GROUP BY d.title
ORDER BY d.title;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
DECLARE
    dept_count INTEGER;
    level_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO dept_count FROM departments;
    SELECT COUNT(*) INTO level_count FROM dept_levels;
    
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Levels Recreated Successfully!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Departments: %', dept_count;
    RAISE NOTICE 'Total Levels: % (should be % × 4)', level_count, dept_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Each department now has exactly 4 levels:';
    RAISE NOTICE '  1. Easy (Beginner) - 10 points';
    RAISE NOTICE '  2. Mid (Intermediate) - 15 points';
    RAISE NOTICE '  3. Hard (Advanced) - 20 points';
    RAISE NOTICE '  4. Extreme (Expert) - 30 points';
END $$;
