-- ============================================
-- Link Questions to New Department Structure
-- ============================================
-- This script updates existing questions to link them
-- to the new General department structure
-- ============================================

DO $$
DECLARE
    v_old_orientation_id UUID;
    v_old_process_id UUID;
    v_old_sop_id UUID;
    v_new_orientation_id UUID;
    v_new_process_id UUID;
    v_new_sop_id UUID;
    v_orientation_count INTEGER;
    v_process_count INTEGER;
    v_sop_count INTEGER;
BEGIN
    -- Find OLD department IDs (before restructure)
    -- These might have title='Orientation', 'Process', 'SOP' without category
    SELECT id INTO v_old_orientation_id 
    FROM departments 
    WHERE title = 'Orientation' AND (category IS NULL OR category = 'Orientation')
    ORDER BY created_at ASC
    LIMIT 1;
    
    SELECT id INTO v_old_process_id 
    FROM departments 
    WHERE title = 'Process' AND (category IS NULL OR category = 'Process')
    ORDER BY created_at ASC
    LIMIT 1;
    
    SELECT id INTO v_old_sop_id 
    FROM departments 
    WHERE title = 'SOP' AND (category IS NULL OR category = 'SOP')
    ORDER BY created_at ASC
    LIMIT 1;
    
    -- Find NEW General department IDs
    SELECT id INTO v_new_orientation_id 
    FROM departments 
    WHERE title = 'General' AND category = 'Orientation';
    
    SELECT id INTO v_new_process_id 
    FROM departments 
    WHERE title = 'General' AND category = 'Process';
    
    SELECT id INTO v_new_sop_id 
    FROM departments 
    WHERE title = 'General' AND category = 'SOP';
    
    -- Check if new departments exist
    IF v_new_orientation_id IS NULL OR v_new_process_id IS NULL OR v_new_sop_id IS NULL THEN
        RAISE EXCEPTION 'New General departments not found. Please run restructure_departments.sql first.';
    END IF;
    
    -- Update questions for Orientation
    IF v_old_orientation_id IS NOT NULL AND v_old_orientation_id != v_new_orientation_id THEN
        UPDATE questions 
        SET dept_id = v_new_orientation_id 
        WHERE dept_id = v_old_orientation_id;
        GET DIAGNOSTICS v_orientation_count = ROW_COUNT;
        RAISE NOTICE 'Updated % Orientation questions', v_orientation_count;
    ELSE
        -- Questions might already be on the new ID, just count them
        SELECT COUNT(*) INTO v_orientation_count
        FROM questions
        WHERE dept_id = v_new_orientation_id;
        RAISE NOTICE 'Found % Orientation questions (already linked)', v_orientation_count;
    END IF;
    
    -- Update questions for Process
    IF v_old_process_id IS NOT NULL AND v_old_process_id != v_new_process_id THEN
        UPDATE questions 
        SET dept_id = v_new_process_id 
        WHERE dept_id = v_old_process_id;
        GET DIAGNOSTICS v_process_count = ROW_COUNT;
        RAISE NOTICE 'Updated % Process questions', v_process_count;
    ELSE
        SELECT COUNT(*) INTO v_process_count
        FROM questions
        WHERE dept_id = v_new_process_id;
        RAISE NOTICE 'Found % Process questions (already linked)', v_process_count;
    END IF;
    
    -- Update questions for SOP
    IF v_old_sop_id IS NOT NULL AND v_old_sop_id != v_new_sop_id THEN
        UPDATE questions 
        SET dept_id = v_new_sop_id 
        WHERE dept_id = v_old_sop_id;
        GET DIAGNOSTICS v_sop_count = ROW_COUNT;
        RAISE NOTICE 'Updated % SOP questions', v_sop_count;
    ELSE
        SELECT COUNT(*) INTO v_sop_count
        FROM questions
        WHERE dept_id = v_new_sop_id;
        RAISE NOTICE 'Found % SOP questions (already linked)', v_sop_count;
    END IF;
    
    RAISE NOTICE 'Question linking complete!';
END $$;

-- Verify the questions are linked correctly
SELECT 
    d.title,
    d.category,
    COUNT(q.id) as question_count
FROM departments d
LEFT JOIN questions q ON d.id = q.dept_id
WHERE d.title = 'General'
GROUP BY d.title, d.category
ORDER BY d.category;

SELECT 'Questions linked successfully!' as status;
