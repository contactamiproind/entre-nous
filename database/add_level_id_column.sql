-- Add level_id column to questions table
ALTER TABLE questions 
ADD COLUMN IF NOT EXISTS level_id UUID REFERENCES dept_levels(id) ON DELETE SET NULL;

-- Now link the "Single Tap Choice" question to the Easy Level
DO $$
DECLARE
    v_dept_id UUID;
    v_easy_level_id UUID;
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
            -- 3. Update the question
            UPDATE questions 
            SET level_id = v_easy_level_id, dept_id = v_dept_id
            WHERE title ILIKE '%Single Tap Choice%';
            
            RAISE NOTICE 'Added level_id column and linked question to Easy Level';
        ELSE
            RAISE NOTICE 'Easy Level not found';
        END IF;
    ELSE
        RAISE NOTICE 'Orientation Department not found';
    END IF;
END $$;
