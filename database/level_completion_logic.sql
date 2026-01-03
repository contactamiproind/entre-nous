-- ============================================
-- LEVEL COMPLETION LOGIC (CORE)
-- ============================================
-- Defines what "Level Complete" means
-- No schema changes - just query logic

-- ============================================
-- DEFINITION: LEVEL 1 (EASY) COMPLETED
-- ============================================

/*
A level is COMPLETE when:
- User has answered ALL questions in that level
- Across ALL Orientation topics
- For that specific level_number

Example: Level 1 (Easy) complete means:
- All Easy questions from Vision answered
- All Easy questions from Values answered
- All Easy questions from Goals answered
- ... (all 16 topics)
*/

-- ============================================
-- QUERY 1: Total Easy Questions in Orientation
-- ============================================

SELECT COUNT(*) AS total_easy_questions
FROM questions q
JOIN departments d ON q.dept_id = d.id
WHERE d.category = 'Orientation'
  AND d.subcategory = 'Mandatory'
  AND q.subcategory = 'Easy';

-- Alternative using dept_levels join:
SELECT COUNT(*) AS total_easy_questions
FROM questions q
JOIN dept_levels dl ON q.dept_id = dl.dept_id AND q.subcategory = dl.title
JOIN departments d ON q.dept_id = d.id
WHERE d.category = 'Orientation'
  AND d.subcategory = 'Mandatory'
  AND dl.level_number = 1;

-- ============================================
-- QUERY 2: Easy Questions User Has Answered
-- ============================================

SELECT COUNT(DISTINCT up.question_id) AS answered_easy_questions
FROM user_progress up
JOIN questions q ON up.question_id = q.id
JOIN departments d ON q.dept_id = d.id
WHERE up.user_id = 'USER-UUID-HERE'  -- Replace with actual user_id
  AND d.category = 'Orientation'
  AND d.subcategory = 'Mandatory'
  AND q.subcategory = 'Easy';

-- ============================================
-- QUERY 3: Check if Level 1 is Complete
-- ============================================

WITH total_easy AS (
    SELECT COUNT(*) AS total
    FROM questions q
    JOIN departments d ON q.dept_id = d.id
    WHERE d.category = 'Orientation'
      AND d.subcategory = 'Mandatory'
      AND q.subcategory = 'Easy'
),
answered_easy AS (
    SELECT COUNT(DISTINCT up.question_id) AS answered
    FROM user_progress up
    JOIN questions q ON up.question_id = q.id
    JOIN departments d ON q.dept_id = d.id
    WHERE up.user_id = 'USER-UUID-HERE'  -- Replace with actual user_id
      AND d.category = 'Orientation'
      AND d.subcategory = 'Mandatory'
      AND q.subcategory = 'Easy'
)
SELECT 
    t.total AS total_easy_questions,
    a.answered AS answered_easy_questions,
    CASE 
        WHEN a.answered >= t.total THEN true
        ELSE false
    END AS level_1_complete,
    CASE 
        WHEN a.answered >= t.total THEN 'Level 2 (Mid) UNLOCKED ✅'
        ELSE 'Level 2 (Mid) LOCKED 🔒'
    END AS next_level_status
FROM total_easy t, answered_easy a;

-- ============================================
-- QUERY 4: Check ALL Levels Completion Status
-- ============================================

WITH level_stats AS (
    SELECT 
        q.subcategory AS level_name,
        CASE q.subcategory
            WHEN 'Easy' THEN 1
            WHEN 'Mid' THEN 2
            WHEN 'Hard' THEN 3
            WHEN 'Extreme' THEN 4
        END AS level_number,
        COUNT(*) AS total_questions,
        COUNT(DISTINCT up.question_id) AS answered_questions
    FROM questions q
    JOIN departments d ON q.dept_id = d.id
    LEFT JOIN user_progress up ON q.id = up.question_id 
        AND up.user_id = 'USER-UUID-HERE'  -- Replace with actual user_id
    WHERE d.category = 'Orientation'
      AND d.subcategory = 'Mandatory'
    GROUP BY q.subcategory
)
SELECT 
    level_number,
    level_name,
    total_questions,
    COALESCE(answered_questions, 0) AS answered_questions,
    CASE 
        WHEN COALESCE(answered_questions, 0) >= total_questions THEN '✅ COMPLETE'
        ELSE '🔒 INCOMPLETE'
    END AS status,
    ROUND((COALESCE(answered_questions, 0)::NUMERIC / total_questions * 100), 2) AS completion_percentage
FROM level_stats
ORDER BY level_number;

-- ============================================
-- QUERY 5: Which Level is Currently Unlocked?
-- ============================================

WITH level_completion AS (
    SELECT 
        CASE q.subcategory
            WHEN 'Easy' THEN 1
            WHEN 'Mid' THEN 2
            WHEN 'Hard' THEN 3
            WHEN 'Extreme' THEN 4
        END AS level_number,
        COUNT(*) AS total_questions,
        COUNT(DISTINCT up.question_id) AS answered_questions
    FROM questions q
    JOIN departments d ON q.dept_id = d.id
    LEFT JOIN user_progress up ON q.id = up.question_id 
        AND up.user_id = 'USER-UUID-HERE'  -- Replace with actual user_id
    WHERE d.category = 'Orientation'
      AND d.subcategory = 'Mandatory'
    GROUP BY q.subcategory
)
SELECT 
    CASE 
        -- Level 1 always unlocked
        WHEN NOT EXISTS (SELECT 1 FROM level_completion WHERE level_number = 1 AND answered_questions >= total_questions)
        THEN 1
        -- Level 2 unlocked if Level 1 complete
        WHEN NOT EXISTS (SELECT 1 FROM level_completion WHERE level_number = 2 AND answered_questions >= total_questions)
             AND EXISTS (SELECT 1 FROM level_completion WHERE level_number = 1 AND answered_questions >= total_questions)
        THEN 2
        -- Level 3 unlocked if Level 2 complete
        WHEN NOT EXISTS (SELECT 1 FROM level_completion WHERE level_number = 3 AND answered_questions >= total_questions)
             AND EXISTS (SELECT 1 FROM level_completion WHERE level_number = 2 AND answered_questions >= total_questions)
        THEN 3
        -- Level 4 unlocked if Level 3 complete
        WHEN NOT EXISTS (SELECT 1 FROM level_completion WHERE level_number = 4 AND answered_questions >= total_questions)
             AND EXISTS (SELECT 1 FROM level_completion WHERE level_number = 3 AND answered_questions >= total_questions)
        THEN 4
        -- All levels complete
        ELSE 5
    END AS current_unlocked_level,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM level_completion WHERE level_number = 1 AND answered_questions >= total_questions)
        THEN 'Easy'
        WHEN NOT EXISTS (SELECT 1 FROM level_completion WHERE level_number = 2 AND answered_questions >= total_questions)
             AND EXISTS (SELECT 1 FROM level_completion WHERE level_number = 1 AND answered_questions >= total_questions)
        THEN 'Mid'
        WHEN NOT EXISTS (SELECT 1 FROM level_completion WHERE level_number = 3 AND answered_questions >= total_questions)
             AND EXISTS (SELECT 1 FROM level_completion WHERE level_number = 2 AND answered_questions >= total_questions)
        THEN 'Hard'
        WHEN NOT EXISTS (SELECT 1 FROM level_completion WHERE level_number = 4 AND answered_questions >= total_questions)
             AND EXISTS (SELECT 1 FROM level_completion WHERE level_number = 3 AND answered_questions >= total_questions)
        THEN 'Extreme'
        ELSE 'All Complete'
    END AS current_level_name;

-- ============================================
-- QUERY 6: User Progress Summary by Topic
-- ============================================

SELECT 
    d.title AS topic,
    q.subcategory AS level,
    COUNT(*) AS total_questions,
    COUNT(DISTINCT up.question_id) AS answered_questions,
    CASE 
        WHEN COUNT(DISTINCT up.question_id) >= COUNT(*) THEN '✅'
        ELSE '🔒'
    END AS status
FROM questions q
JOIN departments d ON q.dept_id = d.id
LEFT JOIN user_progress up ON q.id = up.question_id 
    AND up.user_id = 'USER-UUID-HERE'  -- Replace with actual user_id
WHERE d.category = 'Orientation'
  AND d.subcategory = 'Mandatory'
GROUP BY d.title, q.subcategory
ORDER BY d.title, 
    CASE q.subcategory
        WHEN 'Easy' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'Hard' THEN 3
        WHEN 'Extreme' THEN 4
    END;

-- ============================================
-- QUERY 7: Can User Access Next Level?
-- ============================================

CREATE OR REPLACE FUNCTION can_access_level(
    p_user_id UUID,
    p_level_number INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    prev_level_complete BOOLEAN;
    total_prev INTEGER;
    answered_prev INTEGER;
BEGIN
    -- Level 1 is always accessible
    IF p_level_number = 1 THEN
        RETURN TRUE;
    END IF;
    
    -- Check if previous level is complete
    SELECT 
        COUNT(*),
        COUNT(DISTINCT up.question_id)
    INTO total_prev, answered_prev
    FROM questions q
    JOIN departments d ON q.dept_id = d.id
    LEFT JOIN user_progress up ON q.id = up.question_id AND up.user_id = p_user_id
    WHERE d.category = 'Orientation'
      AND d.subcategory = 'Mandatory'
      AND q.subcategory = CASE p_level_number - 1
          WHEN 1 THEN 'Easy'
          WHEN 2 THEN 'Mid'
          WHEN 3 THEN 'Hard'
          WHEN 4 THEN 'Extreme'
      END;
    
    RETURN COALESCE(answered_prev, 0) >= total_prev;
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT can_access_level('user-uuid', 2);  -- Can access Mid level?
-- SELECT can_access_level('user-uuid', 3);  -- Can access Hard level?

-- ============================================
-- IMPLEMENTATION NOTES
-- ============================================

/*
FLUTTER APP IMPLEMENTATION:

1. Before showing a level, call:
   SELECT can_access_level(:user_id, :level_number);

2. If returns FALSE:
   - Show lock icon 🔒
   - Display message: "Complete Level X first"
   - Disable level button

3. If returns TRUE:
   - Show unlock icon ✅
   - Enable level button
   - Allow user to start quiz

4. After user answers a question:
   - INSERT into user_progress
   - Re-check level completion
   - Update UI to show progress

5. When level completes:
   - Show celebration animation
   - Unlock next level
   - Update progress indicators
*/

-- ============================================
-- TESTING QUERIES
-- ============================================

-- Test: Insert sample progress
INSERT INTO user_progress (user_id, department_id, question_id, question_order, user_answer, is_correct, points_earned)
SELECT 
    'USER-UUID-HERE',
    d.id,
    q.id,
    ROW_NUMBER() OVER (ORDER BY q.id),
    '{"selected_option_id": "test"}'::jsonb,
    true,
    10
FROM questions q
JOIN departments d ON q.dept_id = d.id
WHERE d.category = 'Orientation'
  AND q.subcategory = 'Easy'
LIMIT 5;

-- Then check completion:
-- Run QUERY 3 above to see if level is complete
