-- ============================================
-- ADD ORIENTATION QUESTIONS (LOCKED FLOW)
-- ============================================
-- Linear progression: Easy → Mid → Hard → Extreme
-- Users cannot skip levels
-- Points: Easy=10, Mid=15, Hard=20, Extreme=30

-- ============================================
-- SAMPLE: Orientation – Vision Questions
-- ============================================

DO $$
DECLARE
    vision_dept_id UUID;
    mcq_type_id UUID;
    multi_select_id UUID;
    single_tap_id UUID;
BEGIN
    -- Get IDs
    SELECT id INTO vision_dept_id FROM departments WHERE title = 'Orientation – Vision' LIMIT 1;
    SELECT id INTO mcq_type_id FROM question_types WHERE type = 'mcq' LIMIT 1;
    SELECT id INTO multi_select_id FROM question_types WHERE type = 'multi_select' LIMIT 1;
    SELECT id INTO single_tap_id FROM question_types WHERE type = 'single_tap' LIMIT 1;
    
    IF vision_dept_id IS NOT NULL THEN
        
        -- ============================================
        -- LEVEL 1: EASY (10 points each)
        -- ============================================
        INSERT INTO questions (type_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, vision_dept_id, 'Orientation – Vision', 'Easy', 
             'What is our company vision?', 
             'Select the correct vision statement', 
             'easy', 10),
            
            (mcq_type_id, vision_dept_id, 'Orientation – Vision', 'Easy', 
             'What does our vision focus on?', 
             'Choose the main focus area', 
             'easy', 10),
            
            (single_tap_id, vision_dept_id, 'Orientation – Vision', 'Easy', 
             'Tap the vision icon', 
             'Identify our vision symbol', 
             'easy', 10);
        
        -- ============================================
        -- LEVEL 2: MID (15 points each)
        -- ============================================
        INSERT INTO questions (type_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, vision_dept_id, 'Orientation – Vision', 'Mid', 
             'How does our vision align with industry trends?', 
             'Analyze vision alignment', 
             'medium', 15),
            
            (multi_select_id, vision_dept_id, 'Orientation – Vision', 'Mid', 
             'Select all components of our vision', 
             'Choose all that apply', 
             'medium', 15),
            
            (mcq_type_id, vision_dept_id, 'Orientation – Vision', 'Mid', 
             'What timeframe does our vision target?', 
             'Select the correct timeline', 
             'medium', 15);
        
        -- ============================================
        -- LEVEL 3: HARD (20 points each)
        -- ============================================
        INSERT INTO questions (type_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, vision_dept_id, 'Orientation – Vision', 'Hard', 
             'How do you apply the vision in your daily work?', 
             'Practical application scenario', 
             'hard', 20),
            
            (mcq_type_id, vision_dept_id, 'Orientation – Vision', 'Hard', 
             'What are the key metrics for vision success?', 
             'Identify success indicators', 
             'hard', 20),
            
            (multi_select_id, vision_dept_id, 'Orientation – Vision', 'Hard', 
             'Select all stakeholders impacted by our vision', 
             'Choose all relevant stakeholders', 
             'hard', 20);
        
        -- ============================================
        -- LEVEL 4: EXTREME (30 points each)
        -- ============================================
        INSERT INTO questions (type_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES 
            (mcq_type_id, vision_dept_id, 'Orientation – Vision', 'Extreme', 
             'Design a strategy to achieve our 5-year vision', 
             'Complex strategic planning', 
             'hard', 30),
            
            (mcq_type_id, vision_dept_id, 'Orientation – Vision', 'Extreme', 
             'How would you communicate vision to external partners?', 
             'Advanced communication scenario', 
             'hard', 30);
        
        RAISE NOTICE '✅ Created questions for Orientation – Vision';
        RAISE NOTICE '   Easy: 3 questions (10 pts each)';
        RAISE NOTICE '   Mid: 3 questions (15 pts each)';
        RAISE NOTICE '   Hard: 3 questions (20 pts each)';
        RAISE NOTICE '   Extreme: 2 questions (30 pts each)';
    END IF;
END $$;

-- ============================================
-- TEMPLATE: Add questions for other topics
-- ============================================

/*
REPEAT THE ABOVE PATTERN FOR:
- Orientation – Values
- Orientation – Goals
- Orientation – Brand Guidelines
- Orientation – Job Sheet
- Orientation – Juice of the story
- Orientation – How do you prioritize?
- Orientation – Greetings
- Orientation – Dress Code
- Orientation – ATTENDANCE/ LEAVES
- Orientation – OFFICE DECORUM
- Orientation – Master Class
- Orientation – WORKING STYLE
- Orientation – Vendor Interaction Guidelines
- Orientation – Communication & Response Protocol
- Orientation – Email Etiquette

Just replace vision_dept_id with the appropriate department ID
*/

-- ============================================
-- VERIFY QUESTIONS CREATED
-- ============================================

SELECT 
    d.title as topic,
    q.subcategory as level,
    COUNT(q.id) as question_count,
    SUM(q.points) as total_points
FROM questions q
JOIN departments d ON q.dept_id = d.id
WHERE d.category = 'Orientation' AND d.subcategory = 'Mandatory'
GROUP BY d.title, q.subcategory
ORDER BY d.title, 
    CASE q.subcategory
        WHEN 'Easy' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'Hard' THEN 3
        WHEN 'Extreme' THEN 4
    END;

-- ============================================
-- LOCKED FLOW RULES (Implemented in App Logic)
-- ============================================

/*
BUSINESS RULES (to implement in Flutter app):

1. LINEAR PROGRESSION:
   - User must complete Easy before Mid
   - User must complete Mid before Hard
   - User must complete Hard before Extreme

2. LEVEL COMPLETION:
   - All questions in a level must be answered
   - Minimum score threshold (e.g., 70%) to unlock next level

3. TOPIC COMPLETION:
   - All 4 levels (Easy→Mid→Hard→Extreme) must be completed
   - Only then can user access other departments

4. TRACKING:
   - Use user_progress table to track completion
   - Check user_progress_summary for level completion status
   - Lock/unlock UI based on completion

EXAMPLE QUERY TO CHECK IF USER CAN ACCESS MID LEVEL:

SELECT 
    COUNT(*) as easy_questions,
    SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) as correct_answers
FROM user_progress
WHERE user_id = 'user-uuid'
AND department_id = 'vision-dept-id'
AND question_id IN (
    SELECT id FROM questions 
    WHERE dept_id = 'vision-dept-id' 
    AND subcategory = 'Easy'
);

-- If correct_answers >= (easy_questions * 0.7), unlock Mid level
*/

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Orientation Questions Created!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Sample: Orientation – Vision';
    RAISE NOTICE '  • Easy: 3 questions (10 pts)';
    RAISE NOTICE '  • Mid: 3 questions (15 pts)';
    RAISE NOTICE '  • Hard: 3 questions (20 pts)';
    RAISE NOTICE '  • Extreme: 2 questions (30 pts)';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 LOCKED FLOW RULES:';
    RAISE NOTICE '  1. Must complete Easy → Mid → Hard → Extreme';
    RAISE NOTICE '  2. Cannot skip levels';
    RAISE NOTICE '  3. Must complete all topics before other departments';
    RAISE NOTICE '';
    RAISE NOTICE 'Use this template for remaining 15 topics';
END $$;
