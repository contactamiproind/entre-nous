-- ============================================
-- REMOVE DUPLICATE DEPARTMENTS
-- ============================================
-- Keep only: Orientation (Mandatory)
-- Remove: Orientation (Onboarding), Sales (Training)

-- ============================================
-- STEP 1: Check current departments
-- ============================================

SELECT id, title, category, description
FROM departments
ORDER BY category, title;

-- ============================================
-- STEP 2: Delete old Orientation (Onboarding)
-- ============================================

-- This will delete the Orientation with category = 'Onboarding'
DELETE FROM departments
WHERE title = 'Orientation' 
AND category = 'Onboarding';

-- ============================================
-- STEP 3: Delete Sales department
-- ============================================

DELETE FROM departments
WHERE title = 'Sales';

-- ============================================
-- STEP 4: Verify only Mandatory Orientation remains
-- ============================================

SELECT 
    id,
    title,
    category,
    description
FROM departments;

-- Should show only 1 row:
-- Orientation | Mandatory | Mandatory orientation program for all new employees

-- ============================================
-- STEP 5: Verify dept_levels
-- ============================================

SELECT 
    d.title as department,
    d.category,
    dl.level_number,
    dl.title as level_name,
    dl.category as level_category
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
ORDER BY d.title, dl.level_number;

-- ============================================
-- STEP 6: Clean up orphaned questions (optional)
-- ============================================

-- Delete questions that reference deleted departments
DELETE FROM questions
WHERE dept_id NOT IN (SELECT id FROM departments);

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Cleanup Complete!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Removed:';
    RAISE NOTICE '  ❌ Orientation (Onboarding)';
    RAISE NOTICE '  ❌ Sales (Training)';
    RAISE NOTICE '';
    RAISE NOTICE 'Kept:';
    RAISE NOTICE '  ✅ Orientation (Mandatory)';
    RAISE NOTICE '';
    RAISE NOTICE 'Database now has 1 department only';
END $$;
