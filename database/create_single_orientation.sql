-- ============================================
-- CREATE ONE ORIENTATION DEPARTMENT WITH SUB-TOPICS
-- ============================================
-- Structure: 1 Orientation department with 16 topics inside

-- ============================================
-- STEP 1: Create Single Orientation Department
-- ============================================

INSERT INTO departments (title, description, category, subcategory, tags, levels)
VALUES (
    'Orientation',
    'Mandatory orientation program for all new employees',
    'Orientation',
    'Mandatory',
    '["orientation", "onboarding", "mandatory"]'::jsonb,
    '[
        {"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
        {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
        {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
        {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}
    ]'::jsonb
)
ON CONFLICT DO NOTHING;

-- ============================================
-- STEP 2: Create dept_levels for Orientation
-- ============================================

DO $$
DECLARE
    orientation_id UUID;
BEGIN
    -- Get Orientation department ID
    SELECT id INTO orientation_id 
    FROM departments 
    WHERE title = 'Orientation' AND category = 'Orientation' 
    LIMIT 1;
    
    IF orientation_id IS NOT NULL THEN
        -- Create 4 levels
        INSERT INTO dept_levels (dept_id, level_id, title, category, level_number)
        VALUES 
            (orientation_id, gen_random_uuid(), 'Easy', 'Beginner', 1),
            (orientation_id, gen_random_uuid(), 'Mid', 'Intermediate', 2),
            (orientation_id, gen_random_uuid(), 'Hard', 'Advanced', 3),
            (orientation_id, gen_random_uuid(), 'Extreme', 'Expert', 4)
        ON CONFLICT DO NOTHING;
        
        RAISE NOTICE 'Created 4 levels for Orientation department';
    END IF;
END $$;

-- ============================================
-- STEP 3: Store 16 Topics as JSONB in Department
-- ============================================

DO $$
DECLARE
    orientation_id UUID;
    topics_json JSONB;
BEGIN
    -- Get Orientation department ID
    SELECT id INTO orientation_id 
    FROM departments 
    WHERE title = 'Orientation' AND category = 'Orientation' 
    LIMIT 1;
    
    -- Define 16 topics
    topics_json := '[
        {"id": 1, "name": "Vision", "description": "Company vision and mission statement"},
        {"id": 2, "name": "Values", "description": "Core company values and principles"},
        {"id": 3, "name": "Goals", "description": "Company goals and objectives"},
        {"id": 4, "name": "Brand Guidelines", "description": "Brand identity and usage guidelines"},
        {"id": 5, "name": "Job Sheet", "description": "Job responsibilities and expectations"},
        {"id": 6, "name": "Juice of the story", "description": "Company story and journey"},
        {"id": 7, "name": "How do you prioritize?", "description": "Task prioritization and time management"},
        {"id": 8, "name": "Greetings", "description": "Professional greetings and introductions"},
        {"id": 9, "name": "Dress Code", "description": "Office dress code and appearance standards"},
        {"id": 10, "name": "ATTENDANCE/ LEAVES", "description": "Attendance policies and leave procedures"},
        {"id": 11, "name": "OFFICE DECORUM", "description": "Office behavior and professional conduct"},
        {"id": 12, "name": "Master Class", "description": "Advanced training and skill development"},
        {"id": 13, "name": "WORKING STYLE", "description": "Work culture and collaboration style"},
        {"id": 14, "name": "Vendor Interaction Guidelines", "description": "Guidelines for vendor communication and management"},
        {"id": 15, "name": "Communication & Response Protocol", "description": "Communication standards and response time expectations"},
        {"id": 16, "name": "Email Etiquette", "description": "Professional email writing and communication"}
    ]'::jsonb;
    
    -- Update department with topics
    UPDATE departments
    SET tags = COALESCE(tags, '{}'::jsonb) || jsonb_build_object('topics', topics_json)
    WHERE id = orientation_id;
    
    RAISE NOTICE 'Added 16 topics to Orientation department';
END $$;

-- ============================================
-- STEP 4: Verify Structure
-- ============================================

SELECT 
    id,
    title,
    category,
    subcategory,
    jsonb_array_length(tags->'topics') as topic_count
FROM departments
WHERE category = 'Orientation';

-- ============================================
-- STEP 5: View Topics
-- ============================================

SELECT 
    d.title as department,
    jsonb_array_elements(d.tags->'topics')->>'name' as topic_name,
    jsonb_array_elements(d.tags->'topics')->>'description' as topic_description
FROM departments d
WHERE d.category = 'Orientation';

-- ============================================
-- STEP 6: View Levels
-- ============================================

SELECT 
    d.title as department,
    dl.level_number,
    dl.title as level_name,
    dl.category as level_category
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.category = 'Orientation'
ORDER BY dl.level_number;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Orientation Structure Created!';
    RAISE NOTICE '=================================';
    RAISE NOTICE '1 Department: Orientation';
    RAISE NOTICE '16 Topics (stored as JSON):';
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
    RAISE NOTICE '';
    RAISE NOTICE '4 Levels: Easy, Mid, Hard, Extreme';
    RAISE NOTICE '';
    RAISE NOTICE 'Questions can use tags->''topics''->0->''name'' to reference topics';
END $$;

-- ============================================
-- NOTES FOR ADDING QUESTIONS
-- ============================================

/*
When adding questions, use:
- dept_id = Orientation department ID
- category = 'Orientation'
- subcategory = difficulty level ('Easy', 'Mid', 'Hard', 'Extreme')
- tags = '{"topic": "Vision"}'::jsonb  (to indicate which topic)

Example:
INSERT INTO questions (dept_id, type_id, category, subcategory, title, tags, points)
VALUES (
    'orientation-dept-id',
    'mcq-type-id',
    'Orientation',
    'Easy',
    'What is our company vision?',
    '{"topic": "Vision"}'::jsonb,
    10
);
*/
