-- Check if Level 2 questions exist for all departments

SELECT 
    d.category_name,
    d.id as dept_id,
    COUNT(CASE WHEN q.level = 1 THEN 1 END) as level_1_questions,
    COUNT(CASE WHEN q.level = 2 THEN 1 END) as level_2_questions,
    COUNT(*) as total_questions
FROM departments d
LEFT JOIN questions q ON q.dept_id = d.id
WHERE d.category_name IN ('Orientation', 'Process', 'SOP', 'Production')
GROUP BY d.category_name, d.id
ORDER BY d.category_name;

-- Show actual Level 2 questions
SELECT 
    d.category_name,
    q.id,
    q.question_text,
    q.level
FROM questions q
JOIN departments d ON d.id = q.dept_id
WHERE q.level = 2
  AND d.category_name IN ('Orientation', 'Process', 'SOP', 'Production')
ORDER BY d.category_name, q.id;
