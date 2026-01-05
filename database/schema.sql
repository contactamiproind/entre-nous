-- ============================================
-- Entre Nous Quiz Application - Database Schema
-- ============================================
-- Complete database schema for the quiz application
-- Includes: Tables, Indexes, Functions, Triggers, RLS Policies
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLE: quest_types
-- ============================================
-- Stores question type definitions (MCQ, Match Following, Fill Blank)

CREATE TABLE IF NOT EXISTS quest_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE CHECK (name IN ('mcq', 'match_following', 'fill_blank')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE quest_types IS 'Question type definitions (MCQ, Match Following, Fill in the Blank)';

-- ============================================
-- TABLE: profiles
-- ============================================
-- Stores user profile information

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    avatar_url TEXT,
    bio TEXT,
    date_of_birth DATE,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE profiles IS 'User profile information and role management';

-- Indexes for profiles
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_email ON profiles(email);

-- ============================================
-- TABLE: departments
-- ============================================
-- Stores department/pathway information

CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    subcategory TEXT,
    levels JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE departments IS 'Department/pathway definitions with level information';

-- Indexes for departments
CREATE INDEX idx_departments_category ON departments(category);
CREATE INDEX idx_departments_subcategory ON departments(subcategory);
CREATE INDEX idx_departments_levels ON departments USING GIN(levels);

-- ============================================
-- TABLE: questions
-- ============================================
-- Stores quiz questions

CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_id UUID REFERENCES quest_types(id) ON DELETE SET NULL,
    category TEXT,
    subcategory TEXT,
    title TEXT NOT NULL,
    description TEXT,
    tags TEXT[],
    dept_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    difficulty TEXT DEFAULT 'Easy' CHECK (difficulty IN ('Easy', 'Mid', 'Medium', 'Hard', 'Extreme')),
    points INTEGER DEFAULT 10 CHECK (points > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE questions IS 'Quiz questions with metadata and department association';

-- Indexes for questions
CREATE INDEX idx_questions_type_id ON questions(type_id);
CREATE INDEX idx_questions_category ON questions(category);
CREATE INDEX idx_questions_subcategory ON questions(subcategory);
CREATE INDEX idx_questions_dept_id ON questions(dept_id);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_tags ON questions USING GIN(tags);

-- ============================================
-- TABLE: question_options
-- ============================================
-- Stores answer options for questions

CREATE TABLE IF NOT EXISTS question_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    sub_question_number INTEGER DEFAULT 1,
    option_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    match_pair_left TEXT,
    match_pair_right TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE question_options IS 'Answer options for questions (MCQ options, match pairs, etc.)';

-- Indexes for question_options
CREATE INDEX idx_question_options_question_id ON question_options(question_id);
CREATE INDEX idx_question_options_sub_question ON question_options(question_id, sub_question_number);

-- ============================================
-- TABLE: usr_dept
-- ============================================
-- Stores department assignment summary for users

CREATE TABLE IF NOT EXISTS usr_dept (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    dept_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    dept_name TEXT NOT NULL,
    
    -- Assignment metadata
    assigned_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
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

COMMENT ON TABLE usr_dept IS 'Department assignment summary with aggregated progress tracking';

-- Indexes for usr_dept
CREATE INDEX idx_usr_dept_user_id ON usr_dept(user_id);
CREATE INDEX idx_usr_dept_dept_id ON usr_dept(dept_id);
CREATE INDEX idx_usr_dept_status ON usr_dept(status);
CREATE INDEX idx_usr_dept_is_current ON usr_dept(is_current) WHERE is_current = TRUE;

-- ============================================
-- TABLE: usr_progress
-- ============================================
-- Stores individual question assignments and progress

CREATE TABLE IF NOT EXISTS usr_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign keys
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
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

COMMENT ON TABLE usr_progress IS 'Individual question assignments and user answer tracking';

-- Indexes for usr_progress
CREATE INDEX idx_usr_progress_user_id ON usr_progress(user_id);
CREATE INDEX idx_usr_progress_dept_id ON usr_progress(dept_id);
CREATE INDEX idx_usr_progress_usr_dept_id ON usr_progress(usr_dept_id);
CREATE INDEX idx_usr_progress_question_id ON usr_progress(question_id);
CREATE INDEX idx_usr_progress_status ON usr_progress(status);
CREATE INDEX idx_usr_progress_level ON usr_progress(level_number);
CREATE INDEX idx_usr_progress_is_correct ON usr_progress(is_correct) WHERE is_correct IS NOT NULL;

-- ============================================
-- FUNCTION: update_updated_at_column
-- ============================================
-- Trigger function to automatically update updated_at timestamp

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column IS 'Automatically updates the updated_at timestamp on row updates';

-- ============================================
-- FUNCTION: update_usr_dept_summary
-- ============================================
-- Trigger function to update usr_dept aggregates when usr_progress changes

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

COMMENT ON FUNCTION update_usr_dept_summary IS 'Trigger function to update usr_dept aggregates when usr_progress changes';

-- ============================================
-- FUNCTION: assign_pathway_with_questions
-- ============================================
-- Assigns a department and all its questions to a user

CREATE OR REPLACE FUNCTION assign_pathway_with_questions(
    p_user_id UUID,
    p_dept_id UUID,
    p_assigned_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_usr_dept_id UUID;
    v_dept_name TEXT;
    v_dept_category TEXT;
    v_dept_subcategory TEXT;
    v_total_levels INTEGER;
    v_question_record RECORD;
    v_question_count INTEGER := 0;
BEGIN
    -- Get department details
    SELECT 
        title, 
        category, 
        subcategory, 
        jsonb_array_length(levels)
    INTO 
        v_dept_name, 
        v_dept_category, 
        v_dept_subcategory, 
        v_total_levels
    FROM departments
    WHERE id = p_dept_id;
    
    IF v_dept_name IS NULL THEN
        RAISE EXCEPTION 'Department not found: %', p_dept_id;
    END IF;
    
    -- Check if already assigned
    SELECT id INTO v_usr_dept_id
    FROM usr_dept
    WHERE user_id = p_user_id AND dept_id = p_dept_id;
    
    IF v_usr_dept_id IS NOT NULL THEN
        RAISE EXCEPTION 'Department already assigned to this user';
    END IF;
    
    RAISE NOTICE 'Assigning department: % (ID: %)', v_dept_name, p_dept_id;
    
    -- Create usr_dept record with dept_name
    INSERT INTO usr_dept (
        user_id,
        dept_id,
        dept_name,
        assigned_by,
        total_levels,
        started_at,
        status,
        is_current
    ) VALUES (
        p_user_id,
        p_dept_id,
        v_dept_name,
        p_assigned_by,
        COALESCE(v_total_levels, 0),
        NOW(),
        'active',
        TRUE
    )
    RETURNING id INTO v_usr_dept_id;
    
    RAISE NOTICE 'Created usr_dept record: % with name: %', v_usr_dept_id, v_dept_name;
    
    -- Assign questions from questions table
    FOR v_question_record IN
        SELECT 
            q.id,
            COALESCE(q.title, 'Question') as question_text,
            COALESCE(q.description, '') as question_type,
            COALESCE(q.difficulty, 'Easy') as difficulty,
            v_dept_category as category,
            v_dept_subcategory as subcategory,
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
        WHERE q.dept_id = p_dept_id
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
        
        v_question_count := v_question_count + 1;
    END LOOP;
    
    RAISE NOTICE 'Assigned % questions to user', v_question_count;
    
    IF v_question_count = 0 THEN
        RAISE WARNING 'No questions found for department: %. Make sure questions have dept_id set.', p_dept_id;
    END IF;
    
    RETURN v_usr_dept_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION assign_pathway_with_questions IS 'Assigns a department and all its questions to a user';

-- ============================================
-- FUNCTION: get_user_dept_progress
-- ============================================
-- Retrieves user's progress summary for a department

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

COMMENT ON FUNCTION get_user_dept_progress IS 'Retrieves user progress summary for a specific department';

-- ============================================
-- FUNCTION: get_user_level_questions
-- ============================================
-- Gets questions for user's current or specified level

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

COMMENT ON FUNCTION get_user_level_questions IS 'Gets questions for user current or specified level';

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger to update updated_at on profiles
DROP TRIGGER IF EXISTS trigger_profiles_updated_at ON profiles;
CREATE TRIGGER trigger_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update updated_at on departments
DROP TRIGGER IF EXISTS trigger_departments_updated_at ON departments;
CREATE TRIGGER trigger_departments_updated_at
    BEFORE UPDATE ON departments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update updated_at on questions
DROP TRIGGER IF EXISTS trigger_questions_updated_at ON questions;
CREATE TRIGGER trigger_questions_updated_at
    BEFORE UPDATE ON questions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update updated_at on usr_dept
DROP TRIGGER IF EXISTS trigger_usr_dept_updated_at ON usr_dept;
CREATE TRIGGER trigger_usr_dept_updated_at
    BEFORE UPDATE ON usr_dept
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update updated_at on usr_progress
DROP TRIGGER IF EXISTS trigger_usr_progress_updated_at ON usr_progress;
CREATE TRIGGER trigger_usr_progress_updated_at
    BEFORE UPDATE ON usr_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update usr_dept summary when usr_progress changes
DROP TRIGGER IF EXISTS trigger_update_usr_dept_summary ON usr_progress;
CREATE TRIGGER trigger_update_usr_dept_summary
    AFTER INSERT OR UPDATE OR DELETE ON usr_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_usr_dept_summary();

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE quest_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE usr_dept ENABLE ROW LEVEL SECURITY;
ALTER TABLE usr_progress ENABLE ROW LEVEL SECURITY;

-- Profiles policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
CREATE POLICY "Admins can update all profiles" ON profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Departments policies
DROP POLICY IF EXISTS "Anyone can view departments" ON departments;
CREATE POLICY "Anyone can view departments" ON departments
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admins can manage departments" ON departments;
CREATE POLICY "Admins can manage departments" ON departments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Questions policies
DROP POLICY IF EXISTS "Anyone can view questions" ON questions;
CREATE POLICY "Anyone can view questions" ON questions
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admins can manage questions" ON questions;
CREATE POLICY "Admins can manage questions" ON questions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Question options policies
DROP POLICY IF EXISTS "Anyone can view question options" ON question_options;
CREATE POLICY "Anyone can view question options" ON question_options
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admins can manage question options" ON question_options;
CREATE POLICY "Admins can manage question options" ON question_options
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Quest types policies
DROP POLICY IF EXISTS "Anyone can view quest types" ON quest_types;
CREATE POLICY "Anyone can view quest types" ON quest_types
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- Usr_dept policies
DROP POLICY IF EXISTS "Users can view own assignments" ON usr_dept;
CREATE POLICY "Users can view own assignments" ON usr_dept
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all assignments" ON usr_dept;
CREATE POLICY "Admins can view all assignments" ON usr_dept
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

DROP POLICY IF EXISTS "Admins can manage assignments" ON usr_dept;
CREATE POLICY "Admins can manage assignments" ON usr_dept
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Usr_progress policies
DROP POLICY IF EXISTS "Users can view own progress" ON usr_progress;
CREATE POLICY "Users can view own progress" ON usr_progress
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own progress" ON usr_progress;
CREATE POLICY "Users can update own progress" ON usr_progress
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all progress" ON usr_progress;
CREATE POLICY "Admins can view all progress" ON usr_progress
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

DROP POLICY IF EXISTS "Admins can manage all progress" ON usr_progress;
CREATE POLICY "Admins can manage all progress" ON usr_progress
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ============================================
-- SCHEMA CREATION COMPLETE
-- ============================================

SELECT 'Schema created successfully!' as status;
