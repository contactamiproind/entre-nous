-- ============================================
-- READY-TO-RUN LEVEL COMPLETION QUERIES
-- ============================================
-- These queries use actual user IDs from your database

-- ============================================
-- STEP 1: Get Your User ID
-- ============================================

-- Get all users
SELECT user_id, email, role 
FROM profiles
ORDER BY created_at DESC;

-- Copy one of the user_id values from above

-- ============================================
-- STEP 2: Check Level Completion (REPLACE USER ID)
-- ============================================

-- Replace 'PASTE-USER-ID-HERE' with actual UUID from Step 1

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
    WHERE up.user_id = 'PASTE-USER-ID-HERE'::uuid
      AND d.category = 'Orientation'
      AND d.subcategory = 'Mandatory'
      AND q.subcategory = 'Easy'
)
SELECT 
    t.total AS total_easy_questions,
    COALESCE(a.answered, 0) AS answered_easy_questions,
    CASE 
        WHEN COALESCE(a.answered, 0) >= t.total THEN true
        ELSE false
    END AS level_1_complete,
    CASE 
        WHEN COALESCE(a.answered, 0) >= t.total THEN '✅ Level 2 (Mid) UNLOCKED'
        ELSE '🔒 Level 2 (Mid) LOCKED'
    END AS next_level_status,
    ROUND((COALESCE(a.answered, 0)::NUMERIC / t.total * 100), 2) AS completion_percentage
FROM total_easy t
LEFT JOIN answered_easy a ON true;

-- ============================================
-- STEP 3: Check ALL Levels Status
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
        AND up.user_id = 'PASTE-USER-ID-HERE'::uuid
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
-- ALTERNATIVE: Use naik.abhira2326@gmail.com
-- ============================================

-- If you want to check for your specific user:

WITH user_info AS (
    SELECT user_id FROM profiles WHERE email = 'naik.abhira2326@gmail.com'
),
total_easy AS (
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
    CROSS JOIN user_info u
    WHERE up.user_id = u.user_id
      AND d.category = 'Orientation'
      AND d.subcategory = 'Mandatory'
      AND q.subcategory = 'Easy'
)
SELECT 
    (SELECT email FROM profiles WHERE email = 'naik.abhira2326@gmail.com') AS user_email,
    t.total AS total_easy_questions,
    COALESCE(a.answered, 0) AS answered_easy_questions,
    CASE 
        WHEN COALESCE(a.answered, 0) >= t.total THEN '✅ COMPLETE'
        ELSE '🔒 INCOMPLETE'
    END AS level_1_status,
    ROUND((COALESCE(a.answered, 0)::NUMERIC / t.total * 100), 2) AS completion_percentage
FROM total_easy t
LEFT JOIN answered_easy a ON true;

-- ============================================
-- QUICK CHECK: Do we have any questions yet?
-- ============================================

SELECT 
    d.title,
    d.category,
    d.subcategory,
    COUNT(q.id) as question_count
FROM departments d
LEFT JOIN questions q ON d.id = q.dept_id
WHERE d.category = 'Orientation' AND d.subcategory = 'Mandatory'
GROUP BY d.id, d.title, d.category, d.subcategory
ORDER BY d.title;

-- ============================================
-- QUICK CHECK: Do we have any user progress?
-- ============================================

SELECT 
    p.email,
    COUNT(up.id) as total_answers
FROM profiles p
LEFT JOIN user_progress up ON p.user_id = up.user_id
GROUP BY p.user_id, p.email
ORDER BY total_answers DESC;
