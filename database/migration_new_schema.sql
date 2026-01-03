-- ============================================
-- Migration: Redesign User Assignment & Progress Tables
-- ============================================
-- Purpose: Fix pathway assignment bug where questions are not assigned to users
-- Changes:
--   1. Rename user_pathway → usr_dept (department assignment summary)
--   2. Redesign user_progress → usr_progress (question-level tracking)
-- ============================================

-- ============================================
-- STEP 1: Create new usr_dept table (replaces user_pathway)
-- ============================================
-- This table stores the overall department/pathway assignment summary

CREATE TABLE IF NOT EXISTS usr_dept (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    dept_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    dept_name TEXT NOT NULL,
    
    -- Assignment metadata
    assigned_by UUID,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Status tracking
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused')),
    is_current BOOLEAN DEFAULT TRUE,
    
    -- Progress summary (aggregated from usr_progress)
    total_questions INTEGER DEFAULT 0,
    answered_questions INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    total_score INTEGER DEFAULT 0,
    max_possible_score INTEGER DEFAULT 0,
    progress_percentage NUMERIC(5,2) DEFAULT 0.00,
    
    -- Level tracking
    current_level INTEGER DEFAULT 1,
    completed_levels INTEGER DEFAULT 0,
    total_levels INTEGER DEFAULT 0,
    
    -- Completion tracking
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    last_activity_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_user_dept_active UNIQUE (user_id, dept_id, status)
);

-- Indexes for usr_dept
CREATE INDEX idx_usr_dept_user_id ON usr_dept(user_id);
CREATE INDEX idx_usr_dept_dept_id ON usr_dept(dept_id);
CREATE INDEX idx_usr_dept_status ON usr_dept(status);
CREATE INDEX idx_usr_dept_is_current ON usr_dept(is_current) WHERE is_current = TRUE;

-- ============================================
-- STEP 2: Create new usr_progress table
-- ============================================
-- This table stores individual question assignments and answers

CREATE TABLE IF NOT EXISTS usr_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign keys
    user_id UUID NOT NULL,
    dept_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    usr_dept_id UUID NOT NULL REFERENCES usr_dept(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    
    -- Question metadata (denormalized for performance)
    question_text TEXT,
    question_type TEXT,
    difficulty TEXT,
    category TEXT,
    subcategory TEXT,
    points INTEGER DEFAULT 1,
    
    -- Level information
    level_number INTEGER,
    level_name TEXT,
    
    -- Answer tracking
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'answered', 'skipped', 'flagged')),
    user_answer TEXT,
    is_correct BOOLEAN,
    score_earned INTEGER DEFAULT 0,
    
    -- Attempt tracking
    attempt_count INTEGER DEFAULT 0,
    first_attempted_at TIMESTAMP WITH TIME ZONE,
    last_attempted_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Time tracking
    time_spent_seconds INTEGER DEFAULT 0,
    
    -- Additional metadata
    notes TEXT,
    flagged_for_review BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_user_question_assignment UNIQUE (usr_dept_id, question_id)
);

-- Indexes for usr_progress
CREATE INDEX idx_usr_progress_user_id ON usr_progress(user_id);
CREATE INDEX idx_usr_progress_dept_id ON usr_progress(dept_id);
CREATE INDEX idx_usr_progress_usr_dept_id ON usr_progress(usr_dept_id);
CREATE INDEX idx_usr_progress_question_id ON usr_progress(question_id);
CREATE INDEX idx_usr_progress_status ON usr_progress(status);
CREATE INDEX idx_usr_progress_level ON usr_progress(level_number);
CREATE INDEX idx_usr_progress_is_correct ON usr_progress(is_correct) WHERE is_correct IS NOT NULL;

-- ============================================
-- STEP 3: Create trigger to update usr_dept summary
-- ============================================
-- Automatically update usr_dept aggregates when usr_progress changes

CREATE OR REPLACE FUNCTION update_usr_dept_summary()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the usr_dept summary with aggregated data from usr_progress
    UPDATE usr_dept
    SET 
        total_questions = (
            SELECT COUNT(*) 
            FROM usr_progress 
            WHERE usr_dept_id = COALESCE(NEW.usr_dept_id, OLD.usr_dept_id)
        ),
        answered_questions = (
            SELECT COUNT(*) 
            FROM usr_progress 
            WHERE usr_dept_id = COALESCE(NEW.usr_dept_id, OLD.usr_dept_id) 
            AND status = 'answered'
        ),
        correct_answers = (
            SELECT COUNT(*) 
            FROM usr_progress 
            WHERE usr_dept_id = COALESCE(NEW.usr_dept_id, OLD.usr_dept_id) 
            AND is_correct = TRUE
        ),
        total_score = (
            SELECT COALESCE(SUM(score_earned), 0) 
            FROM usr_progress 
            WHERE usr_dept_id = COALESCE(NEW.usr_dept_id, OLD.usr_dept_id)
        ),
        max_possible_score = (
            SELECT COALESCE(SUM(points), 0) 
            FROM usr_progress 
            WHERE usr_dept_id = COALESCE(NEW.usr_dept_id, OLD.usr_dept_id)
        ),
        progress_percentage = (
            SELECT CASE 
                WHEN COUNT(*) > 0 THEN 
                    ROUND((COUNT(*) FILTER (WHERE status = 'answered')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
                ELSE 0 
            END
            FROM usr_progress 
            WHERE usr_dept_id = COALESCE(NEW.usr_dept_id, OLD.usr_dept_id)
        ),
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.usr_dept_id, OLD.usr_dept_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_usr_dept_summary ON usr_progress;
CREATE TRIGGER trigger_update_usr_dept_summary
    AFTER INSERT OR UPDATE OR DELETE ON usr_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_usr_dept_summary();

-- ============================================
-- STEP 4: Create function to assign pathway with questions
-- ============================================
-- This function assigns a pathway and all its questions to a user

CREATE OR REPLACE FUNCTION assign_pathway_with_questions(
    p_user_id UUID,
    p_dept_id UUID,
    p_assigned_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_usr_dept_id UUID;
    v_dept_name TEXT;
    v_total_levels INTEGER;
    v_question_record RECORD;
BEGIN
    -- Get department name
    SELECT title INTO v_dept_name
    FROM departments
    WHERE id = p_dept_id;
    
    IF v_dept_name IS NULL THEN
        RAISE EXCEPTION 'Department not found: %', p_dept_id;
    END IF;
    
    -- Get total levels from JSONB
    SELECT jsonb_array_length(levels) INTO v_total_levels
    FROM departments
    WHERE id = p_dept_id;
    
    -- Create usr_dept record
    INSERT INTO usr_dept (
        user_id,
        dept_id,
        dept_name,
        assigned_by,
        total_levels,
        started_at
    ) VALUES (
        p_user_id,
        p_dept_id,
        v_dept_name,
        p_assigned_by,
        COALESCE(v_total_levels, 0),
        NOW()
    )
    RETURNING id INTO v_usr_dept_id;
    
    -- Assign all questions for this department/category
    -- Questions are matched by category and subcategory
    FOR v_question_record IN
        SELECT 
            q.id,
            COALESCE(q.title, 'Question') as question_text,
            COALESCE(q.description, '') as question_type,
            COALESCE(q.difficulty, 'Easy') as difficulty,
            q.category,
            q.subcategory,
            COALESCE(q.points, 1) as points,
            CASE 
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) = 'easy' THEN 1
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) IN ('mid', 'medium') THEN 2
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) = 'hard' THEN 3
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) = 'extreme' THEN 4
                ELSE 1
            END as level_number,
            COALESCE(q.difficulty, 'Easy') as level_name
        FROM questions q
        WHERE q.category = (SELECT category FROM departments WHERE id = p_dept_id)
        AND (
            q.subcategory = (SELECT subcategory FROM departments WHERE id = p_dept_id)
            OR (SELECT subcategory FROM departments WHERE id = p_dept_id) IS NULL
        )
    LOOP
        INSERT INTO usr_progress (
            user_id,
            dept_id,
            usr_dept_id,
            question_id,
            question_text,
            question_type,
            difficulty,
            category,
            subcategory,
            points,
            level_number,
            level_name,
            status
        ) VALUES (
            p_user_id,
            p_dept_id,
            v_usr_dept_id,
            v_question_record.id,
            v_question_record.question_text,
            v_question_record.question_type,
            v_question_record.difficulty,
            v_question_record.category,
            v_question_record.subcategory,
            v_question_record.points,
            v_question_record.level_number,
            v_question_record.level_name,
            'pending'
        );
    END LOOP;
    
    RETURN v_usr_dept_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STEP 5: Create helper functions
-- ============================================

-- Function to get user's progress for a department
CREATE OR REPLACE FUNCTION get_user_dept_progress(
    p_user_id UUID,
    p_dept_id UUID
)
RETURNS TABLE (
    dept_name TEXT,
    status TEXT,
    total_questions INTEGER,
    answered_questions INTEGER,
    correct_answers INTEGER,
    progress_percentage NUMERIC,
    current_level INTEGER,
    total_score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ud.dept_name,
        ud.status,
        ud.total_questions,
        ud.answered_questions,
        ud.correct_answers,
        ud.progress_percentage,
        ud.current_level,
        ud.total_score
    FROM usr_dept ud
    WHERE ud.user_id = p_user_id 
    AND ud.dept_id = p_dept_id
    AND ud.status = 'active';
END;
$$ LANGUAGE plpgsql;

-- Function to get questions for user's current level
CREATE OR REPLACE FUNCTION get_user_level_questions(
    p_user_id UUID,
    p_dept_id UUID,
    p_level_number INTEGER DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    question_text TEXT,
    question_type TEXT,
    difficulty TEXT,
    points INTEGER,
    status TEXT,
    user_answer TEXT,
    is_correct BOOLEAN,
    attempt_count INTEGER
) AS $$
DECLARE
    v_current_level INTEGER;
BEGIN
    -- If level not specified, get current level
    IF p_level_number IS NULL THEN
        SELECT current_level INTO v_current_level
        FROM usr_dept
        WHERE user_id = p_user_id 
        AND dept_id = p_dept_id
        AND status = 'active'
        LIMIT 1;
    ELSE
        v_current_level := p_level_number;
    END IF;
    
    RETURN QUERY
    SELECT 
        up.id,
        up.question_text,
        up.question_type,
        up.difficulty,
        up.points,
        up.status,
        up.user_answer,
        up.is_correct,
        up.attempt_count
    FROM usr_progress up
    INNER JOIN usr_dept ud ON up.usr_dept_id = ud.id
    WHERE up.user_id = p_user_id 
    AND up.dept_id = p_dept_id
    AND up.level_number = v_current_level
    AND ud.status = 'active'
    ORDER BY up.created_at;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STEP 6: Create updated_at trigger
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_usr_dept_updated_at ON usr_dept;
CREATE TRIGGER trigger_usr_dept_updated_at
    BEFORE UPDATE ON usr_dept
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_usr_progress_updated_at ON usr_progress;
CREATE TRIGGER trigger_usr_progress_updated_at
    BEFORE UPDATE ON usr_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 7: Migration from old tables (optional)
-- ============================================
-- Uncomment these lines if you want to migrate existing data

/*
-- Migrate user_pathway to usr_dept
INSERT INTO usr_dept (
    user_id,
    dept_id,
    dept_name,
    assigned_at,
    is_current,
    created_at,
    updated_at
)
SELECT 
    up.user_id,
    up.pathway_id,
    COALESCE(up.pathway_name, d.title),
    up.assigned_at,
    up.is_current,
    up.created_at,
    up.updated_at
FROM user_pathway up
LEFT JOIN departments d ON up.pathway_id = d.id
WHERE NOT EXISTS (
    SELECT 1 FROM usr_dept ud 
    WHERE ud.user_id = up.user_id 
    AND ud.dept_id = up.pathway_id
);

-- Note: user_progress migration would require custom logic
-- based on your existing data structure
*/

-- ============================================
-- STEP 8: Add comments for documentation
-- ============================================

COMMENT ON TABLE usr_dept IS 'Stores department/pathway assignments with aggregated progress summary';
COMMENT ON TABLE usr_progress IS 'Stores individual question assignments and user answers';
COMMENT ON FUNCTION assign_pathway_with_questions IS 'Assigns a pathway and all its questions to a user';
COMMENT ON FUNCTION update_usr_dept_summary IS 'Trigger function to update usr_dept aggregates when usr_progress changes';

-- ============================================
-- End of migration
-- ============================================
