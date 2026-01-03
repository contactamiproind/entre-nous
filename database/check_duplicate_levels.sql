-- Check for duplicate levels in dept_levels table
SELECT 
    dept_id,
    level_number,
    COUNT(*) as count
FROM 
    dept_levels
GROUP BY 
    dept_id, level_number
HAVING 
    COUNT(*) > 1;

-- Also show some sample data to see the duplicates
SELECT * FROM dept_levels ORDER BY dept_id, level_number;
