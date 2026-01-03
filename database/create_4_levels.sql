-- ============================================
-- CREATE 4 DIFFICULTY LEVELS
-- Easy, Mid, Hard, Extreme Hard
-- ============================================

-- This uses the existing schema without any changes
-- Just inserts data into dept_levels table

-- ============================================
-- STEP 1: Create a sample department (if needed)
-- ============================================

INSERT INTO departments (title, description, category, subcategory, tags, levels)
VALUES (
    'Sales Training',
    'Complete sales training program with 4 difficulty levels',
    'Training',
    'Sales',
    '["sales", "training", "customer-service"]'::jsonb,
    '[
        {"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
        {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
        {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
        {"level_id": "4", "level_number": 4, "title": "Extreme Hard", "category": "Expert"}
    ]'::jsonb
)
ON CONFLICT DO NOTHING
RETURNING id, title;

-- ============================================
-- STEP 2: Create dept_levels for each difficulty
-- ============================================

DO $$
DECLARE
    dept_id UUID;
BEGIN
    -- Get the department ID
    SELECT id INTO dept_id FROM departments WHERE title = 'Sales Training' LIMIT 1;
    
    IF dept_id IS NOT NULL THEN
        -- Insert 4 difficulty levels
        INSERT INTO dept_levels (dept_id, level_id, title, category, level_number)
        VALUES 
            (dept_id, gen_random_uuid(), 'Easy', 'Beginner', 1),
            (dept_id, gen_random_uuid(), 'Mid', 'Intermediate', 2),
            (dept_id, gen_random_uuid(), 'Hard', 'Advanced', 3),
            (dept_id, gen_random_uuid(), 'Extreme Hard', 'Expert', 4)
        ON CONFLICT DO NOTHING;
        
        RAISE NOTICE '✅ Created 4 levels for Sales Training department';
    END IF;
END $$;

-- ============================================
-- STEP 3: Create sample questions for each level
-- ============================================

DO $$
DECLARE
    dept_id UUID;
    mcq_type_id UUID;
BEGIN
    -- Get IDs
    SELECT id INTO dept_id FROM departments WHERE title = 'Sales Training' LIMIT 1;
    SELECT id INTO mcq_type_id FROM question_types WHERE type = 'mcq' LIMIT 1;
    
    IF dept_id IS NOT NULL AND mcq_type_id IS NOT NULL THEN
        -- Easy Level Questions
        INSERT INTO questions (type_id, dept_id, category, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, dept_id, 'Sales Basics', 'What is the first step in a sales call?', 'Select the correct answer', 'easy', 10),
            (mcq_type_id, dept_id, 'Sales Basics', 'What does CRM stand for?', 'Choose the best answer', 'easy', 10);
        
        -- Mid Level Questions
        INSERT INTO questions (type_id, dept_id, category, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, dept_id, 'Sales Techniques', 'Which technique is best for handling objections?', 'Select the appropriate method', 'medium', 15),
            (mcq_type_id, dept_id, 'Sales Techniques', 'How do you qualify a lead?', 'Choose the correct process', 'medium', 15);
        
        -- Hard Level Questions
        INSERT INTO questions (type_id, dept_id, category, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, dept_id, 'Advanced Sales', 'What is consultative selling?', 'Identify the correct approach', 'hard', 20),
            (mcq_type_id, dept_id, 'Advanced Sales', 'How to close a complex B2B deal?', 'Select the best strategy', 'hard', 20);
        
        -- Extreme Hard Level Questions
        INSERT INTO questions (type_id, dept_id, category, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, dept_id, 'Expert Sales', 'Design a sales strategy for enterprise clients', 'Comprehensive approach required', 'hard', 30),
            (mcq_type_id, dept_id, 'Expert Sales', 'Handle multi-stakeholder negotiations', 'Complex scenario analysis', 'hard', 30);
        
        RAISE NOTICE '✅ Created sample questions for all 4 levels';
    END IF;
END $$;

-- ============================================
-- STEP 4: Verify the levels were created
-- ============================================

SELECT 
    d.title as department,
    dl.level_number,
    dl.title as level_name,
    dl.category,
    COUNT(q.id) as question_count
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON d.id = q.dept_id AND 
    CASE 
        WHEN dl.level_number = 1 THEN q.difficulty = 'easy'
        WHEN dl.level_number = 2 THEN q.difficulty = 'medium'
        WHEN dl.level_number IN (3, 4) THEN q.difficulty = 'hard'
    END
WHERE d.title = 'Sales Training'
GROUP BY d.title, dl.level_number, dl.title, dl.category
ORDER BY dl.level_number;

-- ============================================
-- ALTERNATIVE: Update existing Orientation department
-- ============================================

-- If you want to add 4 levels to Orientation instead:

/*
DO $$
DECLARE
    dept_id UUID;
BEGIN
    SELECT id INTO dept_id FROM departments WHERE title = 'Orientation' LIMIT 1;
    
    IF dept_id IS NOT NULL THEN
        -- First, delete existing levels
        DELETE FROM dept_levels WHERE dept_id = dept_id;
        
        -- Insert 4 new levels
        INSERT INTO dept_levels (dept_id, level_id, title, category, level_number)
        VALUES 
            (dept_id, gen_random_uuid(), 'Easy', 'Beginner', 1),
            (dept_id, gen_random_uuid(), 'Mid', 'Intermediate', 2),
            (dept_id, gen_random_uuid(), 'Hard', 'Advanced', 3),
            (dept_id, gen_random_uuid(), 'Extreme Hard', 'Expert', 4);
        
        -- Update the levels JSON in departments table
        UPDATE departments
        SET levels = '[
            {"level_id": "1", "level_number": 1, "title": "Easy", "category": "Beginner"},
            {"level_id": "2", "level_number": 2, "title": "Mid", "category": "Intermediate"},
            {"level_id": "3", "level_number": 3, "title": "Hard", "category": "Advanced"},
            {"level_id": "4", "level_number": 4, "title": "Extreme Hard", "category": "Expert"}
        ]'::jsonb
        WHERE id = dept_id;
        
        RAISE NOTICE '✅ Updated Orientation with 4 difficulty levels';
    END IF;
END $$;
*/

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ 4 Difficulty Levels Created!';
    RAISE NOTICE '=================================';
    RAISE NOTICE '1. Easy - Beginner (10 points)';
    RAISE NOTICE '2. Mid - Intermediate (15 points)';
    RAISE NOTICE '3. Hard - Advanced (20 points)';
    RAISE NOTICE '4. Extreme Hard - Expert (30 points)';
    RAISE NOTICE '';
    RAISE NOTICE 'Department: Sales Training';
    RAISE NOTICE 'Questions created for each level';
END $$;
