-- ============================================
-- INSERT NEW QUESTION TYPES
-- ============================================
-- No schema changes - just adding data to existing table

-- ============================================
-- STEP 1: Check existing question types
-- ============================================
SELECT * FROM question_types ORDER BY type;

-- ============================================
-- STEP 2: Insert 10 new question types
-- ============================================

INSERT INTO question_types (type) 
VALUES 
    ('single_tap'),
    ('multi_select'),
    ('card_match'),
    ('stack_cards'),
    ('scenario_decision'),
    ('sequence_builder'),
    ('simulation'),
    ('drag_drop'),
    ('memory_pick'),
    ('visual_builder')
ON CONFLICT DO NOTHING;

-- ============================================
-- STEP 3: Verify all question types
-- ============================================

SELECT 
    type,
    id,
    created_at
FROM question_types
ORDER BY created_at;

-- ============================================
-- STEP 4: Count question types
-- ============================================

SELECT 
    COUNT(*) as total_question_types
FROM question_types;

-- Should show 13 types total (3 original + 10 new)

-- ============================================
-- QUESTION TYPE DESCRIPTIONS
-- ============================================

/*
ORIGINAL TYPES:
1. mcq - Multiple Choice Question (single correct answer)
2. match - Match Following (pair items)
3. fill - Fill in the Blank

NEW INTERACTIVE TYPES:
4. single_tap - Tap/click single item to answer
5. multi_select - Select multiple correct answers
6. card_match - Match cards by flipping/dragging
7. stack_cards - Stack cards in correct order
8. scenario_decision - Choose decision in a scenario
9. sequence_builder - Build correct sequence/order
10. simulation - Interactive simulation question
11. drag_drop - Drag and drop elements
12. memory_pick - Memory game style question
13. visual_builder - Build visual answer (diagram/flowchart)
*/

-- ============================================
-- EXAMPLE: Create questions with new types
-- ============================================

DO $$
DECLARE
    dept_id UUID;
    single_tap_id UUID;
    multi_select_id UUID;
    card_match_id UUID;
BEGIN
    -- Get department and question type IDs
    SELECT id INTO dept_id FROM departments WHERE title = 'Orientation' LIMIT 1;
    SELECT id INTO single_tap_id FROM question_types WHERE type = 'single_tap' LIMIT 1;
    SELECT id INTO multi_select_id FROM question_types WHERE type = 'multi_select' LIMIT 1;
    SELECT id INTO card_match_id FROM question_types WHERE type = 'card_match' LIMIT 1;
    
    IF dept_id IS NOT NULL THEN
        -- Example: Single Tap Question
        INSERT INTO questions (type_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES (
            single_tap_id,
            dept_id,
            'Orientation',
            'Easy',
            'Tap the company logo',
            'Identify our company logo from the options',
            'easy',
            10
        );
        
        -- Example: Multi Select Question
        INSERT INTO questions (type_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES (
            multi_select_id,
            dept_id,
            'Orientation',
            'Mid',
            'Select all core values',
            'Choose all that apply to our company values',
            'medium',
            15
        );
        
        -- Example: Card Match Question
        INSERT INTO questions (type_id, dept_id, category, subcategory, title, description, difficulty, points)
        VALUES (
            card_match_id,
            dept_id,
            'Orientation',
            'Hard',
            'Match departments to their functions',
            'Flip and match cards to pair departments with their roles',
            'hard',
            20
        );
        
        RAISE NOTICE '✅ Created example questions with new types';
    END IF;
END $$;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Question Types Updated!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Total Types: 13';
    RAISE NOTICE '';
    RAISE NOTICE 'Original Types (3):';
    RAISE NOTICE '  • mcq';
    RAISE NOTICE '  • match';
    RAISE NOTICE '  • fill';
    RAISE NOTICE '';
    RAISE NOTICE 'New Interactive Types (10):';
    RAISE NOTICE '  • single_tap';
    RAISE NOTICE '  • multi_select';
    RAISE NOTICE '  • card_match';
    RAISE NOTICE '  • stack_cards';
    RAISE NOTICE '  • scenario_decision';
    RAISE NOTICE '  • sequence_builder';
    RAISE NOTICE '  • simulation';
    RAISE NOTICE '  • drag_drop';
    RAISE NOTICE '  • memory_pick';
    RAISE NOTICE '  • visual_builder';
END $$;
