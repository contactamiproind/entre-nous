-- ============================================
-- ORGANIZE QUESTIONS BY CATEGORY & SUBCATEGORY
-- Without changing schema
-- ============================================

-- Category = Orientation ID or Department name
-- Subcategory = Difficulty level (Easy, Mid, Hard, Extreme)

-- ============================================
-- STEP 1: Create Orientation Department
-- ============================================

INSERT INTO departments (title, description, category, subcategory, tags, levels)
VALUES (
    'Orientation',
    'New employee orientation program',
    'Onboarding',
    'General',
    '["orientation", "onboarding"]'::jsonb,
    '[
        {"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
        {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
        {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
        {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}
    ]'::jsonb
)
ON CONFLICT DO NOTHING
RETURNING id;

-- ============================================
-- STEP 2: Create Sales Department
-- ============================================

INSERT INTO departments (title, description, category, subcategory, tags, levels)
VALUES (
    'Sales',
    'Sales training and techniques',
    'Training',
    'Sales',
    '["sales", "training"]'::jsonb,
    '[
        {"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
        {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
        {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
        {"level_id": "4", "level_number": 4, "title": "Extreme", "category": "Expert"}
    ]'::jsonb
)
ON CONFLICT DO NOTHING
RETURNING id;

-- ============================================
-- STEP 3: Create Questions with Category & Subcategory
-- ============================================

DO $$
DECLARE
    orientation_id UUID;
    sales_id UUID;
    mcq_type_id UUID;
BEGIN
    -- Get department IDs
    SELECT id INTO orientation_id FROM departments WHERE title = 'Orientation' LIMIT 1;
    SELECT id INTO sales_id FROM departments WHERE title = 'Sales' LIMIT 1;
    SELECT id INTO mcq_type_id FROM question_types WHERE type = 'mcq' LIMIT 1;
    
    IF orientation_id IS NOT NULL AND mcq_type_id IS NOT NULL THEN
        
        -- ORIENTATION - EASY LEVEL
        INSERT INTO questions (type_id, orientation_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, orientation_id, orientation_id, 'Orientation', 'Easy', 'What is our company name?', 'Basic company information', 'easy', 10),
            (mcq_type_id, orientation_id, orientation_id, 'Orientation', 'Easy', 'Where is the main office located?', 'Company location', 'easy', 10),
            (mcq_type_id, orientation_id, orientation_id, 'Orientation', 'Easy', 'What time does work start?', 'Working hours', 'easy', 10);
        
        -- ORIENTATION - MID LEVEL
        INSERT INTO questions (type_id, orientation_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, orientation_id, orientation_id, 'Orientation', 'Mid', 'What is our company mission?', 'Company values', 'medium', 15),
            (mcq_type_id, orientation_id, orientation_id, 'Orientation', 'Mid', 'What are the core values?', 'Company culture', 'medium', 15),
            (mcq_type_id, orientation_id, orientation_id, 'Orientation', 'Mid', 'What is the dress code policy?', 'Company policies', 'medium', 15);
        
        -- ORIENTATION - HARD LEVEL
        INSERT INTO questions (type_id, orientation_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, orientation_id, orientation_id, 'Orientation', 'Hard', 'Explain the escalation process', 'Advanced procedures', 'hard', 20),
            (mcq_type_id, orientation_id, orientation_id, 'Orientation', 'Hard', 'What is the emergency protocol?', 'Safety procedures', 'hard', 20),
            (mcq_type_id, orientation_id, orientation_id, 'Orientation', 'Hard', 'Describe the reporting structure', 'Organizational hierarchy', 'hard', 20);
        
        -- ORIENTATION - EXTREME LEVEL
        INSERT INTO questions (type_id, orientation_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, orientation_id, orientation_id, 'Orientation', 'Extreme', 'Complex compliance scenario', 'Expert level compliance', 'hard', 30),
            (mcq_type_id, orientation_id, orientation_id, 'Orientation', 'Extreme', 'Multi-department coordination', 'Cross-functional expertise', 'hard', 30);
        
        RAISE NOTICE '✅ Created Orientation questions with 4 difficulty levels';
    END IF;
    
    IF sales_id IS NOT NULL AND mcq_type_id IS NOT NULL THEN
        
        -- SALES - EASY LEVEL
        INSERT INTO questions (type_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, sales_id, 'Sales', 'Easy', 'What is a lead?', 'Basic sales terminology', 'easy', 10),
            (mcq_type_id, sales_id, 'Sales', 'Easy', 'What does CRM stand for?', 'Sales tools', 'easy', 10);
        
        -- SALES - MID LEVEL
        INSERT INTO questions (type_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, sales_id, 'Sales', 'Mid', 'How to handle objections?', 'Sales techniques', 'medium', 15),
            (mcq_type_id, sales_id, 'Sales', 'Mid', 'What is the sales funnel?', 'Sales process', 'medium', 15);
        
        -- SALES - HARD LEVEL
        INSERT INTO questions (type_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, sales_id, 'Sales', 'Hard', 'Consultative selling approach', 'Advanced sales', 'hard', 20),
            (mcq_type_id, sales_id, 'Sales', 'Hard', 'Complex B2B negotiations', 'Enterprise sales', 'hard', 20);
        
        -- SALES - EXTREME LEVEL
        INSERT INTO questions (type_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, sales_id, 'Sales', 'Extreme', 'Multi-stakeholder deal strategy', 'Expert sales strategy', 'hard', 30),
            (mcq_type_id, sales_id, 'Sales', 'Extreme', 'Global account management', 'Enterprise expertise', 'hard', 30);
        
        RAISE NOTICE '✅ Created Sales questions with 4 difficulty levels';
    END IF;
END $$;

-- ============================================
-- STEP 4: Verify Questions Organization
-- ============================================

SELECT 
    category as department,
    subcategory as difficulty_level,
    COUNT(*) as question_count,
    SUM(points) as total_points
FROM questions
GROUP BY category, subcategory
ORDER BY category, 
    CASE subcategory
        WHEN 'Easy' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'Hard' THEN 3
        WHEN 'Extreme' THEN 4
    END;

-- ============================================
-- STEP 5: Query Questions by Level
-- ============================================

-- Get all Easy questions for Orientation
SELECT id, category, subcategory, title, points
FROM questions
WHERE category = 'Orientation' AND subcategory = 'Easy';

-- Get all Hard questions for Sales
SELECT id, category, subcategory, title, points
FROM questions
WHERE category = 'Sales' AND subcategory = 'Hard';

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Questions Organized Successfully!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Structure:';
    RAISE NOTICE '  category = Orientation/Sales (Department)';
    RAISE NOTICE '  subcategory = Easy/Mid/Hard/Extreme (Level)';
    RAISE NOTICE '';
    RAISE NOTICE 'Difficulty Levels:';
    RAISE NOTICE '  1. Easy - 10 points';
    RAISE NOTICE '  2. Mid - 15 points';
    RAISE NOTICE '  3. Hard - 20 points';
    RAISE NOTICE '  4. Extreme - 30 points';
END $$;
