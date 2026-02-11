-- Simple check: Show ALL departments to understand the structure
SELECT 
    id,
    category,
    created_at
FROM departments
ORDER BY category, created_at;

-- Count departments by category
SELECT 
    category,
    COUNT(*) as total_count
FROM departments
GROUP BY category
ORDER BY category;
