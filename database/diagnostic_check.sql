-- ============================================
-- Diagnostic Query - Check Department and Question Setup
-- ============================================
-- Run this to see what's actually in the database
-- ============================================

-- 1. Check all departments
SELECT 
    id,
    title,
    category,
    description,
    display_order,
    created_at
FROM departments
ORDER BY 
    CASE WHEN title = 'General' THEN 0 ELSE 1 END,
    display_order,
    category;

-- 2. Check questions linked to departments
SELECT 
    d.title as dept_title,
    d.category as dept_category,
    COUNT(q.id) as question_count,
    d.id as dept_id
FROM departments d
LEFT JOIN questions q ON d.id = q.dept_id
GROUP BY d.id, d.title, d.category
ORDER BY 
    CASE WHEN d.title = 'General' THEN 0 ELSE 1 END,
    d.category;

-- 3. Check user assignments
SELECT 
    p.email,
    d.title,
    d.category,
    ud.id as usr_dept_id,
    COUNT(DISTINCT uq.id) as questions_assigned
FROM profiles p
JOIN usr_dept ud ON p.user_id = ud.user_id
JOIN departments d ON ud.dept_id = d.id
LEFT JOIN usr_questions uq ON ud.id = uq.usr_dept_id
WHERE p.role = 'user'
GROUP BY p.email, d.title, d.category, ud.id
ORDER BY p.email, d.category;

-- 4. Sample questions for Orientation
SELECT 
    q.id,
    q.question_text,
    q.dept_id,
    d.title,
    d.category
FROM questions q
JOIN departments d ON q.dept_id = d.id
WHERE d.category = 'Orientation'
LIMIT 5;
