-- ============================================
-- Debug: Why Questions Are Not Being Assigned
-- ============================================
-- Run this in Supabase SQL Editor to diagnose the issue
-- ============================================

-- Step 1: Check if usr_dept was created
SELECT 
    id,
    user_id,
    dept_id,
    dept_name,
    total_questions,
    answered_questions,
    created_at
FROM usr_dept
ORDER BY created_at DESC
LIMIT 5;

-- Step 2: Check if any usr_progress records exist
SELECT COUNT(*) as progress_count FROM usr_progress;

-- Step 3: Get department details to see category/subcategory
SELECT 
    id,
    title,
    category,
    subcategory,
    jsonb_array_length(levels) as level_count
FROM departments
WHERE title LIKE '%Orientation%' OR title LIKE '%Vision%'
LIMIT 5;

-- Step 4: Check if questions exist for that category
SELECT 
    category,
    subcategory,
    COUNT(*) as question_count
FROM questions
GROUP BY category, subcategory
ORDER BY question_count DESC;

-- Step 5: Sample questions to see structure
SELECT 
    id,
    title,
    category,
    subcategory,
    difficulty,
    points
FROM questions
LIMIT 10;

-- Step 6: Test the matching logic
-- Replace with actual dept_id from Step 1
DO $$
DECLARE
    test_dept_id UUID := '32d2764f-ed76-40db-8886-bcf5923f91a1'; -- Replace with your dept_id
    dept_category TEXT;
    dept_subcategory TEXT;
    matching_questions INTEGER;
BEGIN
    -- Get department category
    SELECT category, subcategory INTO dept_category, dept_subcategory
    FROM departments WHERE id = test_dept_id;
    
    RAISE NOTICE 'Department category: %, subcategory: %', dept_category, dept_subcategory;
    
    -- Count matching questions
    SELECT COUNT(*) INTO matching_questions
    FROM questions q
    WHERE q.category = dept_category
    AND (q.subcategory = dept_subcategory OR dept_subcategory IS NULL);
    
    RAISE NOTICE 'Matching questions found: %', matching_questions;
    
    IF matching_questions = 0 THEN
        RAISE WARNING 'NO QUESTIONS FOUND! Check if questions.category matches departments.category';
    END IF;
END $$;

-- Step 7: Check for NULL categories
SELECT 
    'departments' as table_name,
    COUNT(*) as total,
    COUNT(category) as with_category,
    COUNT(*) - COUNT(category) as null_category
FROM departments
UNION ALL
SELECT 
    'questions' as table_name,
    COUNT(*) as total,
    COUNT(category) as with_category,
    COUNT(*) - COUNT(category) as null_category
FROM questions;
