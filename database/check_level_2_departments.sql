-- Check if Level 2 departments exist in the database
-- This is REQUIRED for the level progression to work properly

SELECT 
    'Level 2 Departments Check' as check_type,
    category,
    COUNT(*) as count,
    STRING_AGG(id::text, ', ') as dept_ids
FROM departments
WHERE difficulty = 2  -- Assuming 'difficulty' column is used for levels
GROUP BY category
ORDER BY category;

-- If the above returns empty, try with 'level' column
SELECT 
    'Alternative: Check with level column' as check_type,
    category,
    COUNT(*) as count
FROM departments
WHERE level = 2
GROUP BY category
ORDER BY category;

-- Show all departments to understand the structure
SELECT 
    'All Departments' as check_type,
    category,
    id,
    COALESCE(difficulty, level) as dept_level
FROM departments
ORDER BY category, COALESCE(difficulty, level);
