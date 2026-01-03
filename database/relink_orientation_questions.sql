-- Link user's question to the new "Easy" level

DO $$
DECLARE
    v_dept_id UUID;
    v_easy_level_id UUID;
    v_question_id UUID;
BEGIN
    -- 1. Get Orientation Department ID
    SELECT id INTO v_dept_id FROM departments WHERE title = 'Orientation' LIMIT 1;
    
    IF v_dept_id IS NOT NULL THEN
        -- 2. Get "Easy" Level ID (Level 1)
        SELECT id INTO v_easy_level_id 
        FROM dept_levels 
        WHERE dept_id = v_dept_id AND level_number = 1 
        LIMIT 1;
        
        IF v_easy_level_id IS NOT NULL THEN
            -- 3. Link "Single Tap Choice" question to this level
            -- We update matching title OR any question that was previously in Orientation (if we can identify them)
            
            -- Try to find by title first
            UPDATE questions 
            SET level_id = v_easy_level_id, dept_id = v_dept_id
            WHERE title ILIKE '%Single Tap Choice%';
            
            RAISE NOTICE 'Updated specific question to Easy Level';
            
            -- OPTIONAL: Also link ALL questions that might have lost their level link 
            -- but are marked as 'easy' difficulty
            -- UPDATE questions 
            -- SET level_id = v_easy_level_id, dept_id = v_dept_id
            -- WHERE difficulty = 'easy' AND (level_id IS NULL OR dept_id = v_dept_id);
            
        ELSE
            RAISE NOTICE 'Easy Level not found';
        END IF;
    ELSE
        RAISE NOTICE 'Orientation Department not found';
    END IF;
END $$;
