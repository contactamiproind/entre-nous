-- Corrected query to check Level 2 questions for Orientation
-- Using 'category' instead of 'category_name'

-- 1. Check if Level 2 question exists for Orientation
SELECT 
    d.category,
    q.id,
    q.question_text,
    q.level
FROM questions q
JOIN departments d ON d.id = q.dept_id
WHERE d.category = 'Orientation'
  AND q.level = 2;

-- 2. Check user's current level for Orientation
SELECT 
    d.category,
    ud.current_level
FROM usr_dept ud
JOIN departments d ON d.id = ud.dept_id
WHERE ud.user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6'
  AND d.category = 'Orientation';

-- 3. Count all questions for Orientation by level
SELECT 
    d.category,
    q.level,
    COUNT(*) as question_count
FROM questions q
JOIN departments d ON d.id = q.dept_id
WHERE d.category = 'Orientation'
GROUP BY d.category, q.level
ORDER BY q.level;
