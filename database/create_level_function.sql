-- ============================================
-- CREATE LEVEL ACCESS FUNCTION
-- ============================================
-- This function checks if a user can access a specific level
-- Based on whether they completed the previous level

CREATE OR REPLACE FUNCTION can_access_level(
    p_user_id UUID,
    p_level_number INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    total_prev INTEGER;
    answered_prev INTEGER;
BEGIN
    -- Level 1 (Easy) is always accessible
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
    
    -- If no questions exist yet, allow access (for testing)
    IF total_prev = 0 THEN
        RETURN TRUE;
    END IF;
    
    -- Check if all previous level questions are answered
    RETURN COALESCE(answered_prev, 0) >= total_prev;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST THE FUNCTION
-- ============================================

-- Test with your user
SELECT can_access_level(
    (SELECT user_id FROM profiles WHERE email = 'naik.abhira2326@gmail.com'),
    1
) AS can_access_level_1;

SELECT can_access_level(
    (SELECT user_id FROM profiles WHERE email = 'naik.abhira2326@gmail.com'),
    2
) AS can_access_level_2;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=================================';
    RAISE NOTICE '✅ Function Created Successfully!';
    RAISE NOTICE '=================================';
    RAISE NOTICE 'Function: can_access_level(user_id, level_number)';
    RAISE NOTICE '';
    RAISE NOTICE 'Usage in Flutter:';
    RAISE NOTICE '  await supabase.rpc(''can_access_level'', params: {';
    RAISE NOTICE '    ''p_user_id'': userId,';
    RAISE NOTICE '    ''p_level_number'': 2';
    RAISE NOTICE '  });';
    RAISE NOTICE '';
    RAISE NOTICE 'Returns: true or false';
END $$;
