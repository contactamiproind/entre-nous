-- Check current user progress and Level 2 question status

-- 1. Check user's current level
SELECT 
    'Current Levels' as check_type,
    d.category_name,
    ud.current_level
FROM usr_dept ud
JOIN departments d ON d.id = ud.dept_id
WHERE ud.user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6'
ORDER BY d.category_name;

-- 2. Check Level 2 questions for Orientation
SELECT 
    'Level 2 Questions' as check_type,
    d.category_name,
    q.id,
    q.question_text,
    q.level
FROM questions q
JOIN departments d ON d.id = q.dept_id
WHERE d.category_name = 'Orientation'
  AND q.level = 2;

-- 3. Check user progress on Orientation questions
SELECT 
    'User Progress' as check_type,
    q.level,
    q.id as question_id,
    q.question_text,
    up.status
FROM questions q
JOIN departments d ON d.id = q.dept_id
LEFT JOIN usr_dept ud ON ud.dept_id = d.id AND ud.user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6'
LEFT JOIN usr_progress up ON up.question_id = q.id AND up.usr_dept_id = ud.id
WHERE d.category_name = 'Orientation'
ORDER BY q.level, q.id;

-- 4. Count questions by level for Orientation
SELECT 
    'Question Count' as check_type,
    d.category_name,
    q.level,
    COUNT(*) as question_count
FROM questions q
JOIN departments d ON d.id = q.dept_id
WHERE d.category_name = 'Orientation'
GROUP BY d.category_name, q.level
ORDER BY q.level;
