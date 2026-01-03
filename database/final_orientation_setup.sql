-- ============================================
-- FINAL SETUP: ONE ORIENTATION WITH 16 SUB-TOPICS
-- ============================================

-- ============================================
-- STEP 1: Delete questions referencing Orientation
-- ============================================

DELETE FROM questions 
WHERE dept_id IN (
    SELECT id FROM departments 
    WHERE title = 'Orientation' OR title LIKE 'Orientation%'
);

-- ============================================
-- STEP 2: Delete ALL Orientation departments
-- ============================================

DELETE FROM departments WHERE title = 'Orientation' OR title LIKE 'Orientation%';

-- ============================================
-- STEP 3: Create ONE Orientation Department
-- ============================================

INSERT INTO departments (title, description, category, subcategory)
VALUES (
    'Orientation',
    'Mandatory orientation program with 16 sub-topics',
    'Orientation',
    'Mandatory'
)
RETURNING id;

-- ============================================
-- STEP 4: Add 16 Sub-Topics as JSONB
-- ============================================

UPDATE departments
SET tags = jsonb_build_object(
    'topics', jsonb_build_array(
        jsonb_build_object('id', 1, 'name', 'Vision', 'description', 'Company vision and mission statement'),
        jsonb_build_object('id', 2, 'name', 'Values', 'description', 'Core company values and principles'),
        jsonb_build_object('id', 3, 'name', 'Goals', 'description', 'Company goals and objectives'),
        jsonb_build_object('id', 4, 'name', 'Brand Guidelines', 'description', 'Brand identity and usage guidelines'),
        jsonb_build_object('id', 5, 'name', 'Job Sheet', 'description', 'Job responsibilities and expectations'),
        jsonb_build_object('id', 6, 'name', 'Juice of the story', 'description', 'Company story and journey'),
        jsonb_build_object('id', 7, 'name', 'How do you prioritize?', 'description', 'Task prioritization and time management'),
        jsonb_build_object('id', 8, 'name', 'Greetings', 'description', 'Professional greetings and introductions'),
        jsonb_build_object('id', 9, 'name', 'Dress Code', 'description', 'Office dress code and appearance standards'),
        jsonb_build_object('id', 10, 'name', 'ATTENDANCE/ LEAVES', 'description', 'Attendance policies and leave procedures'),
        jsonb_build_object('id', 11, 'name', 'OFFICE DECORUM', 'description', 'Office behavior and professional conduct'),
        jsonb_build_object('id', 12, 'name', 'Master Class', 'description', 'Advanced training and skill development'),
        jsonb_build_object('id', 13, 'name', 'WORKING STYLE', 'description', 'Work culture and collaboration style'),
        jsonb_build_object('id', 14, 'name', 'Vendor Interaction Guidelines', 'description', 'Guidelines for vendor communication and management'),
        jsonb_build_object('id', 15, 'name', 'Communication & Response Protocol', 'description', 'Communication standards and response time expectations'),
        jsonb_build_object('id', 16, 'name', 'Email Etiquette', 'description', 'Professional email writing and communication')
    )
)
WHERE title = 'Orientation' AND category = 'Orientation';

-- ============================================
-- STEP 5: Create 4 Levels for Orientation
-- ============================================

DO $$
DECLARE
    orientation_id UUID;
BEGIN
    SELECT id INTO orientation_id FROM departments WHERE title = 'Orientation' AND category = 'Orientation';
    
    IF orientation_id IS NOT NULL THEN
        INSERT INTO dept_levels (dept_id, level_id, title, category, level_number)
        VALUES 
            (orientation_id, gen_random_uuid(), 'Easy', 'Beginner', 1),
            (orientation_id, gen_random_uuid(), 'Mid', 'Intermediate', 2),
            (orientation_id, gen_random_uuid(), 'Hard', 'Advanced', 3),
            (orientation_id, gen_random_uuid(), 'Extreme', 'Expert', 4);
        
        RAISE NOTICE '✅ Created 4 levels for Orientation';
    END IF;
END $$;

-- ============================================
-- STEP 6: Verify Structure
-- ============================================

-- Show department
SELECT 
    id,
    title,
    category,
    subcategory,
    description
FROM departments
WHERE title = 'Orientation';

-- Show sub-topics
SELECT 
    jsonb_array_elements(tags->'topics')->>'id' as topic_id,
    jsonb_array_elements(tags->'topics')->>'name' as topic_name,
    jsonb_array_elements(tags->'topics')->>'description' as description
FROM departments
WHERE title = 'Orientation';

-- Show levels
SELECT 
    dl.level_number,
    dl.title as level_name,
    dl.category
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.title = 'Orientation'
ORDER BY dl.level_number;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Orientation Setup Complete!';
    RAISE NOTICE '=================================';
    RAISE NOTICE '';
    RAISE NOTICE '📚 Structure:';
    RAISE NOTICE '  1 Department: Orientation (Mandatory)';
    RAISE NOTICE '  16 Sub-Topics: Vision, Values, Goals, etc.';
    RAISE NOTICE '  4 Levels: Easy, Mid, Hard, Extreme';
    RAISE NOTICE '';
    RAISE NOTICE '📝 Sub-Topics:';
    RAISE NOTICE '  1. Vision';
    RAISE NOTICE '  2. Values';
    RAISE NOTICE '  3. Goals';
    RAISE NOTICE '  4. Brand Guidelines';
    RAISE NOTICE '  5. Job Sheet';
    RAISE NOTICE '  6. Juice of the story';
    RAISE NOTICE '  7. How do you prioritize?';
    RAISE NOTICE '  8. Greetings';
    RAISE NOTICE '  9. Dress Code';
    RAISE NOTICE '  10. ATTENDANCE/ LEAVES';
    RAISE NOTICE '  11. OFFICE DECORUM';
    RAISE NOTICE '  12. Master Class';
    RAISE NOTICE '  13. WORKING STYLE';
    RAISE NOTICE '  14. Vendor Interaction Guidelines';
    RAISE NOTICE '  15. Communication & Response Protocol';
    RAISE NOTICE '  16. Email Etiquette';
END $$;
