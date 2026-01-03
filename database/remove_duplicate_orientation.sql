-- ============================================
-- FIND AND REMOVE DUPLICATE ORIENTATION DEPARTMENTS
-- ============================================

-- ============================================
-- STEP 1: Show all Orientation departments
-- ============================================

SELECT 
    id,
    title,
    category,
    subcategory,
    created_at
FROM departments
WHERE title = 'Orientation' OR title LIKE 'Orientation%'
ORDER BY created_at;

-- ============================================
-- STEP 2: Count levels per Orientation department
-- ============================================

SELECT 
    d.id as dept_id,
    d.title,
    d.category,
    COUNT(dl.id) as level_count
FROM departments d
LEFT JOIN dept_levels dl ON d.id = dl.dept_id
WHERE d.title = 'Orientation' OR d.title LIKE 'Orientation%'
GROUP BY d.id, d.title, d.category
ORDER BY d.created_at;

-- ============================================
-- STEP 3: Delete the OLDER Orientation department
-- ============================================

-- This keeps the NEWEST one and deletes the older one
DELETE FROM departments
WHERE id IN (
    SELECT id
    FROM (
        SELECT 
            id,
            ROW_NUMBER() OVER (
                PARTITION BY title 
                ORDER BY created_at DESC
            ) as rn
        FROM departments
        WHERE title = 'Orientation'
    ) t
    WHERE rn > 1
);

-- Note: dept_levels will be automatically deleted due to CASCADE

-- ============================================
-- STEP 4: Verify - Should show only 1 Orientation
-- ============================================

SELECT 
    d.id,
    d.title,
    d.category,
    COUNT(dl.id) as level_count
FROM departments d
LEFT JOIN dept_levels dl ON d.id = dl.dept_id
WHERE d.title = 'Orientation'
GROUP BY d.id, d.title, d.category;

-- ============================================
-- STEP 5: Show remaining levels
-- ============================================

SELECT 
    d.title as department,
    dl.level_number,
    dl.title as level_name
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.title = 'Orientation'
ORDER BY dl.level_number;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
DECLARE
    dept_count INTEGER;
    level_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO dept_count 
    FROM departments 
    WHERE title = 'Orientation';
    
    SELECT COUNT(*) INTO level_count 
    FROM dept_levels dl
    JOIN departments d ON dl.dept_id = d.id
    WHERE d.title = 'Orientation';
    
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Duplicate Departments Removed!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Orientation Departments: %', dept_count;
    RAISE NOTICE 'Total Levels: %', level_count;
    RAISE NOTICE '';
    IF dept_count = 1 AND level_count = 4 THEN
        RAISE NOTICE '✅ Perfect! 1 department with 4 levels';
    ELSE
        RAISE NOTICE '⚠️  Expected: 1 department with 4 levels';
        RAISE NOTICE '   Got: % departments with % levels', dept_count, level_count;
    END IF;
END $$;
