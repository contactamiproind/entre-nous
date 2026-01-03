-- ============================================
-- Verify usr_dept Data
-- ============================================
-- Check if dept_name is being saved correctly
-- ============================================

-- Check usr_dept records
SELECT 
    id,
    user_id,
    dept_id,
    dept_name,  -- This should NOT be NULL
    total_questions,
    answered_questions,
    status,
    created_at
FROM usr_dept
ORDER BY created_at DESC
LIMIT 10;

-- If dept_name is NULL, the RPC function needs to be fixed
-- Check departments table to see what names exist
SELECT 
    id,
    title,
    name,
    category,
    subcategory
FROM departments
ORDER BY title;

-- Check if the RPC function is correctly saving dept_name
-- Run this to see the function definition
SELECT 
    proname as function_name,
    prosrc as source_code
FROM pg_proc
WHERE proname = 'assign_pathway_with_questions';
