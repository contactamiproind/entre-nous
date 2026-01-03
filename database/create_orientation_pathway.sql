-- ============================================
-- CREATE ORIENTATION AS MANDATORY PATHWAY
-- ============================================
-- No schema changes - just inserting data

-- ============================================
-- STEP 1: Create Orientation Department
-- ============================================

INSERT INTO departments (title, description, category, subcategory, tags, levels)
VALUES (
    'Orientation',
    'Mandatory orientation program for all new employees',
    'Mandatory',
    'Onboarding',
    '["orientation", "mandatory", "onboarding", "new-employee"]'::jsonb,
    '[
        {"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
        {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
        {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
        {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}
    ]'::jsonb
)
ON CONFLICT DO NOTHING
RETURNING id, title, category;

-- ============================================
-- STEP 2: Create dept_levels for Orientation
-- ============================================

DO $$
DECLARE
    orientation_id UUID;
BEGIN
    -- Get the Orientation department ID
    SELECT id INTO orientation_id FROM departments WHERE title = 'Orientation' AND category = 'Mandatory' LIMIT 1;
    
    IF orientation_id IS NOT NULL THEN
        -- Insert 4 difficulty levels
        INSERT INTO dept_levels (dept_id, level_id, title, category, level_number)
        VALUES 
            (orientation_id, gen_random_uuid(), 'Easy', 'Beginner', 1),
            (orientation_id, gen_random_uuid(), 'Mid', 'Intermediate', 2),
            (orientation_id, gen_random_uuid(), 'Hard', 'Advanced', 3),
            (orientation_id, gen_random_uuid(), 'Extreme', 'Expert', 4)
        ON CONFLICT DO NOTHING;
        
        RAISE NOTICE '✅ Created 4 levels for Orientation pathway';
    END IF;
END $$;

-- ============================================
-- STEP 3: Verify Orientation was created
-- ============================================

SELECT 
    d.id,
    d.title,
    d.category,
    d.description,
    COUNT(dl.id) as level_count
FROM departments d
LEFT JOIN dept_levels dl ON d.id = dl.dept_id
WHERE d.title = 'Orientation' AND d.category = 'Mandatory'
GROUP BY d.id, d.title, d.category, d.description;

-- ============================================
-- STEP 4: Show all levels for Orientation
-- ============================================

SELECT 
    dl.level_number,
    dl.title as level_name,
    dl.category as level_category
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.title = 'Orientation' AND d.category = 'Mandatory'
ORDER BY dl.level_number;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ ORIENTATION Pathway Created!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Title: Orientation';
    RAISE NOTICE 'Category: Mandatory';
    RAISE NOTICE 'Type: Parent Pathway';
    RAISE NOTICE '';
    RAISE NOTICE 'Levels Created:';
    RAISE NOTICE '  1. Easy - Beginner';
    RAISE NOTICE '  2. Mid - Intermediate';
    RAISE NOTICE '  3. Hard - Advanced';
    RAISE NOTICE '  4. Extreme - Expert';
    RAISE NOTICE '';
    RAISE NOTICE '📍 Table: departments';
    RAISE NOTICE '👉 This is the mandatory pathway for all users';
END $$;
