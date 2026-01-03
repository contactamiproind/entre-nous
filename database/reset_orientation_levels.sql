-- Reconfigure Orientation levels to: Easy, Medium, Hard, Extreme Hard

DO $$
DECLARE
    v_dept_id UUID;
BEGIN
    -- Get the Orientation department ID
    SELECT id INTO v_dept_id FROM departments WHERE title = 'Orientation' LIMIT 1;
    
    IF v_dept_id IS NOT NULL THEN
        -- Delete existing levels for Orientation
        DELETE FROM dept_levels WHERE dept_id = v_dept_id;

        -- Insert new levels
        INSERT INTO dept_levels (dept_id, level_number, level_name, description, question_count) VALUES
        (v_dept_id, 1, 'Easy', 'Start your journey with basic concepts', 5),
        (v_dept_id, 2, 'Medium', 'Step up the challenge', 5),
        (v_dept_id, 3, 'Hard', 'Test your deeper understanding', 5),
        (v_dept_id, 4, 'Extreme Hard', 'Only for the experts', 5);
        
        RAISE NOTICE 'Orientation levels updated successfully';
    ELSE
        RAISE NOTICE 'Orientation department not found';
    END IF;
END $$;
