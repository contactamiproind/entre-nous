-- ============================================
-- CREATE ORIENTATION SUB-TOPICS
-- ============================================
-- Creates 16 orientation topics as departments
-- All linked by category = 'Orientation', subcategory = 'Mandatory'

-- ============================================
-- INSERT 16 ORIENTATION TOPICS
-- ============================================

INSERT INTO departments (title, description, category, subcategory, tags, levels)
VALUES 
    -- Topic 1: Vision
    ('Orientation – Vision', 'Company vision and mission statement', 'Orientation', 'Mandatory', '["orientation", "vision", "mission"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 2: Values
    ('Orientation – Values', 'Core company values and principles', 'Orientation', 'Mandatory', '["orientation", "values", "culture"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 3: Goals
    ('Orientation – Goals', 'Company goals and objectives', 'Orientation', 'Mandatory', '["orientation", "goals", "objectives"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 4: Brand Guidelines
    ('Orientation – Brand Guidelines', 'Brand identity and usage guidelines', 'Orientation', 'Mandatory', '["orientation", "brand", "guidelines"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 5: Job Sheet
    ('Orientation – Job Sheet', 'Job responsibilities and expectations', 'Orientation', 'Mandatory', '["orientation", "job", "responsibilities"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 6: Juice of the story
    ('Orientation – Juice of the story', 'Company story and journey', 'Orientation', 'Mandatory', '["orientation", "story", "history"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 7: How do you prioritize?
    ('Orientation – How do you prioritize?', 'Task prioritization and time management', 'Orientation', 'Mandatory', '["orientation", "prioritization", "time-management"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 8: Greetings
    ('Orientation – Greetings', 'Professional greetings and introductions', 'Orientation', 'Mandatory', '["orientation", "greetings", "etiquette"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 9: Dress Code
    ('Orientation – Dress Code', 'Office dress code and appearance standards', 'Orientation', 'Mandatory', '["orientation", "dress-code", "appearance"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 10: ATTENDANCE/ LEAVES
    ('Orientation – ATTENDANCE/ LEAVES', 'Attendance policies and leave procedures', 'Orientation', 'Mandatory', '["orientation", "attendance", "leaves"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 11: OFFICE DECORUM
    ('Orientation – OFFICE DECORUM', 'Office behavior and professional conduct', 'Orientation', 'Mandatory', '["orientation", "decorum", "conduct"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 12: Master Class
    ('Orientation – Master Class', 'Advanced training and skill development', 'Orientation', 'Mandatory', '["orientation", "masterclass", "training"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 13: WORKING STYLE
    ('Orientation – WORKING STYLE', 'Work culture and collaboration style', 'Orientation', 'Mandatory', '["orientation", "working-style", "culture"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 14: Vendor Interaction Guidelines
    ('Orientation – Vendor Interaction Guidelines', 'Guidelines for vendor communication and management', 'Orientation', 'Mandatory', '["orientation", "vendor", "guidelines"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 15: Communication & Response Protocol
    ('Orientation – Communication & Response Protocol', 'Communication standards and response time expectations', 'Orientation', 'Mandatory', '["orientation", "communication", "protocol"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb),
    
    -- Topic 16: Email Etiquette
    ('Orientation – Email Etiquette', 'Professional email writing and communication', 'Orientation', 'Mandatory', '["orientation", "email", "etiquette"]'::jsonb,
    '[{"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
      {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
      {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
      {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}]'::jsonb)
ON CONFLICT DO NOTHING;

-- ============================================
-- CREATE dept_levels FOR ALL TOPICS
-- ============================================

DO $$
DECLARE
    topic_record RECORD;
BEGIN
    -- Loop through all Orientation topics
    FOR topic_record IN 
        SELECT id, title FROM departments 
        WHERE category = 'Orientation' AND subcategory = 'Mandatory'
    LOOP
        -- Insert 4 levels for each topic
        INSERT INTO dept_levels (dept_id, level_id, title, category, level_number)
        VALUES 
            (topic_record.id, gen_random_uuid(), 'Easy', 'Beginner', 1),
            (topic_record.id, gen_random_uuid(), 'Mid', 'Intermediate', 2),
            (topic_record.id, gen_random_uuid(), 'Hard', 'Advanced', 3),
            (topic_record.id, gen_random_uuid(), 'Extreme', 'Expert', 4)
        ON CONFLICT DO NOTHING;
        
        RAISE NOTICE 'Created levels for: %', topic_record.title;
    END LOOP;
END $$;

-- ============================================
-- VERIFY ALL TOPICS CREATED
-- ============================================

SELECT 
    title,
    category,
    subcategory,
    description
FROM departments
WHERE category = 'Orientation' AND subcategory = 'Mandatory'
ORDER BY title;

-- ============================================
-- COUNT TOPICS AND LEVELS
-- ============================================

SELECT 
    'Total Orientation Topics' as metric,
    COUNT(*) as count
FROM departments
WHERE category = 'Orientation' AND subcategory = 'Mandatory'

UNION ALL

SELECT 
    'Total Levels',
    COUNT(*)
FROM dept_levels dl
JOIN departments d ON dl.dept_id = d.id
WHERE d.category = 'Orientation' AND d.subcategory = 'Mandatory';

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Orientation Topics Created!';
    RAISE NOTICE '=================================';
    RAISE NOTICE '16 Mandatory Topics:';
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
    RAISE NOTICE 'Each topic has 4 levels: Easy, Mid, Hard, Extreme';
    RAISE NOTICE 'Total: 16 topics × 4 levels = 64 levels';
END $$;
