-- ============================================
-- ADD VISION LEVELS - CORRECTED
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Check current "Orientation - Vision" levels
SELECT 
    d.title as department,
    dl.level_number,
    dl.title as level_title,
    dl.category
FROM departments d
LEFT JOIN dept_levels dl ON d.id = dl.dept_id
WHERE d.title = 'Orientation - Vision'
ORDER BY dl.level_number;

-- Step 2: Add missing Hard and Expert levels to "Orientation - Vision"
INSERT INTO dept_levels (dept_id, level_number, title, category)
SELECT 
    d.id as dept_id,
    levels.level_number,
    levels.title,
    levels.category
FROM departments d
CROSS JOIN (
    VALUES 
        (3, 'Hard', 'Hard'),
        (4, 'Expert', 'Expert')
) AS levels(level_number, title, category)
WHERE d.title = 'Orientation - Vision';

-- Step 3: Verify all "Orientation - Vision" levels
SELECT 
    d.title as department,
    dl.level_number,
    dl.title as level_title,
    dl.category
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
WHERE d.title = 'Orientation - Vision'
ORDER BY dl.level_number;
