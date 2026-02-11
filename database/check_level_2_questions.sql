-- Check if Level 2 questions exist
SELECT 
    'Questions by Level' as check_type,
    level,
    COUNT(*) as question_count
FROM questions
GROUP BY level
ORDER BY level;

-- Check Level 2 questions by department
SELECT 
    'Level 2 Questions by Department' as check_type,
    d.category,
    COUNT(q.id) as level_2_question_count
FROM questions q
JOIN departments d ON d.id = q.dept_id
WHERE q.level = 2
GROUP BY d.category
ORDER BY d.category;
