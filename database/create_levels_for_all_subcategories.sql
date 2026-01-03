-- Create 4 levels for each of the 16 Orientation subcategories
-- This will create 64 total levels (16 subcategories × 4 levels each)
-- Using gen_random_uuid() to generate unique IDs for each level

DO $$
DECLARE
    dept_record RECORD;
BEGIN
    -- Loop through all Orientation departments
    FOR dept_record IN 
        SELECT id, title, subcategory 
        FROM departments 
        WHERE category = 'Orientation' 
        AND subcategory IS NOT NULL
    LOOP
        -- Insert 4 levels for each department with unique UUIDs and level numbers
        INSERT INTO dept_levels (dept_id, level_id, level_number, title, created_at, updated_at) VALUES
        (dept_record.id, gen_random_uuid(), 1, 'Easy', NOW(), NOW()),
        (dept_record.id, gen_random_uuid(), 2, 'Mid', NOW(), NOW()),
        (dept_record.id, gen_random_uuid(), 3, 'Hard', NOW(), NOW()),
        (dept_record.id, gen_random_uuid(), 4, 'Extreme', NOW(), NOW());
        
        RAISE NOTICE 'Created 4 levels for: %', dept_record.title;
    END LOOP;
END $$;

-- Verify the creation
SELECT 
    d.title as department,
    d.subcategory,
    dl.level_number,
    dl.title as level,
    COUNT(*) OVER (PARTITION BY d.id) as levels_count
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
WHERE d.category = 'Orientation'
ORDER BY d.title, dl.level_number;

-- Summary count
SELECT 
    d.subcategory,
    COUNT(dl.id) as level_count
FROM departments d
LEFT JOIN dept_levels dl ON d.id = dl.dept_id
WHERE d.category = 'Orientation'
GROUP BY d.subcategory
ORDER BY d.subcategory;
