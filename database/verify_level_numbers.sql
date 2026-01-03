-- ============================================
-- VERIFY AND FIX LEVEL NUMBERS
-- ============================================
-- CRITICAL: Ensures correct level progression
-- Easy=1, Mid=2, Hard=3, Extreme=4

-- ============================================
-- STEP 1: CHECK CURRENT LEVEL NUMBERS
-- ============================================

SELECT 
    d.title as topic,
    dl.title as level_name,
    dl.level_number,
    dl.category as level_category,
    CASE 
        WHEN dl.title = 'Easy' AND dl.level_number = 1 THEN '✅ CORRECT'
        WHEN dl.title = 'Mid' AND dl.level_number = 2 THEN '✅ CORRECT'
        WHEN dl.title = 'Hard' AND dl.level_number = 3 THEN '✅ CORRECT'
        WHEN dl.title = 'Extreme' AND dl.level_number = 4 THEN '✅ CORRECT'
        ELSE '❌ WRONG'
    END as status
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.category = 'Orientation' AND d.subcategory = 'Mandatory'
ORDER BY d.title, dl.level_number;

-- ============================================
-- STEP 2: FIX INCORRECT LEVEL NUMBERS
-- ============================================

-- Fix Easy levels (should be 1)
UPDATE dept_levels
SET level_number = 1
WHERE title = 'Easy'
AND dept_id IN (
    SELECT id FROM departments 
    WHERE category = 'Orientation' AND subcategory = 'Mandatory'
)
AND level_number != 1;

-- Fix Mid levels (should be 2)
UPDATE dept_levels
SET level_number = 2
WHERE title = 'Mid'
AND dept_id IN (
    SELECT id FROM departments 
    WHERE category = 'Orientation' AND subcategory = 'Mandatory'
)
AND level_number != 2;

-- Fix Hard levels (should be 3)
UPDATE dept_levels
SET level_number = 3
WHERE title = 'Hard'
AND dept_id IN (
    SELECT id FROM departments 
    WHERE category = 'Orientation' AND subcategory = 'Mandatory'
)
AND level_number != 3;

-- Fix Extreme levels (should be 4)
UPDATE dept_levels
SET level_number = 4
WHERE title = 'Extreme'
AND dept_id IN (
    SELECT id FROM departments 
    WHERE category = 'Orientation' AND subcategory = 'Mandatory'
)
AND level_number != 4;

-- ============================================
-- STEP 3: VERIFY ALL FIXED
-- ============================================

SELECT 
    d.title as topic,
    dl.title as level_name,
    dl.level_number,
    dl.category as level_category
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.category = 'Orientation' AND d.subcategory = 'Mandatory'
ORDER BY d.title, dl.level_number;

-- ============================================
-- STEP 4: COUNT VERIFICATION
-- ============================================

-- Should show 16 topics × 4 levels = 64 total
SELECT 
    'Total Orientation Levels' as metric,
    COUNT(*) as count
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.category = 'Orientation' AND d.subcategory = 'Mandatory';

-- Verify each level number count
SELECT 
    dl.level_number,
    dl.title as level_name,
    COUNT(*) as count
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.category = 'Orientation' AND d.subcategory = 'Mandatory'
GROUP BY dl.level_number, dl.title
ORDER BY dl.level_number;

-- Should show:
-- level_number | level_name | count
-- 1            | Easy       | 16
-- 2            | Mid        | 16
-- 3            | Hard       | 16
-- 4            | Extreme    | 16

-- ============================================
-- STEP 5: VERIFY MAPPING IS CORRECT
-- ============================================

-- Check for any mismatches
SELECT 
    d.title as topic,
    dl.title as level_name,
    dl.level_number,
    CASE 
        WHEN dl.title = 'Easy' THEN 1
        WHEN dl.title = 'Mid' THEN 2
        WHEN dl.title = 'Hard' THEN 3
        WHEN dl.title = 'Extreme' THEN 4
    END as expected_number,
    CASE 
        WHEN dl.level_number = CASE 
            WHEN dl.title = 'Easy' THEN 1
            WHEN dl.title = 'Mid' THEN 2
            WHEN dl.title = 'Hard' THEN 3
            WHEN dl.title = 'Extreme' THEN 4
        END THEN '✅ MATCH'
        ELSE '❌ MISMATCH'
    END as validation
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.category = 'Orientation' AND d.subcategory = 'Mandatory'
ORDER BY d.title, dl.level_number;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
DECLARE
    total_levels INTEGER;
    correct_levels INTEGER;
BEGIN
    -- Count total levels
    SELECT COUNT(*) INTO total_levels
    FROM dept_levels dl
    JOIN departments d ON dl.dept_id = d.id
    WHERE d.category = 'Orientation' AND d.subcategory = 'Mandatory';
    
    -- Count correctly numbered levels
    SELECT COUNT(*) INTO correct_levels
    FROM dept_levels dl
    JOIN departments d ON dl.dept_id = d.id
    WHERE d.category = 'Orientation' AND d.subcategory = 'Mandatory'
    AND (
        (dl.title = 'Easy' AND dl.level_number = 1) OR
        (dl.title = 'Mid' AND dl.level_number = 2) OR
        (dl.title = 'Hard' AND dl.level_number = 3) OR
        (dl.title = 'Extreme' AND dl.level_number = 4)
    );
    
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Level Number Verification';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Total Levels: %', total_levels;
    RAISE NOTICE 'Correctly Numbered: %', correct_levels;
    
    IF total_levels = correct_levels THEN
        RAISE NOTICE '';
        RAISE NOTICE '✅ ALL LEVEL NUMBERS CORRECT!';
        RAISE NOTICE '';
        RAISE NOTICE 'Mapping:';
        RAISE NOTICE '  Easy → 1';
        RAISE NOTICE '  Mid → 2';
        RAISE NOTICE '  Hard → 3';
        RAISE NOTICE '  Extreme → 4';
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '❌ FOUND % INCORRECT LEVELS', (total_levels - correct_levels);
        RAISE NOTICE 'Run the UPDATE statements to fix';
    END IF;
END $$;
