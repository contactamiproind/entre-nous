-- ============================================
-- FINAL SIMPLIFIED SCHEMA (Based on Diagrams)
-- ============================================

-- Drop existing tables if they exist
DROP TABLE IF EXISTS question_child CASCADE;
DROP TABLE IF EXISTS user_progress CASCADE;
DROP VIEW IF EXISTS user_progress_summary CASCADE;
DROP TABLE IF EXISTS user_pathway CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS question_types CASCADE;
DROP TABLE IF EXISTS dept_levels CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ============================================
-- TABLE: departments
-- ============================================
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    subcategory TEXT,
    tags JSONB DEFAULT '[]'::jsonb,
    levels JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLE: dept_levels (child table of departments)
-- ============================================
CREATE TABLE dept_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dept_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    level_id UUID DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    category TEXT,
    level_number INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLE: question_types
-- ============================================
CREATE TABLE question_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL, -- 'mcq', 'match', 'fill'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default question types
INSERT INTO question_types (type) VALUES 
    ('mcq'),
    ('match'),
    ('fill');

-- ============================================
-- TABLE: questions
-- ============================================
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_id UUID REFERENCES question_types(id),
    orientation_id UUID REFERENCES departments(id),
    dept_id UUID REFERENCES departments(id),
    category TEXT,
    subcategory TEXT,
    title TEXT NOT NULL,
    description TEXT,
    tags JSONB DEFAULT '[]'::jsonb,
    difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
    points INTEGER DEFAULT 10,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLE: question_child (for sub-questions)
-- ============================================
CREATE TABLE question_child (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    sub_question_number INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLE: profiles
-- ============================================
CREATE TABLE profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    role TEXT CHECK (role IN ('admin', 'user')) DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABLE: user_progress
-- ============================================
CREATE TABLE user_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id),
    question_id UUID REFERENCES questions(id),
    question_order INTEGER,
    user_answer JSONB,
    is_correct BOOLEAN,
    points_earned INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- VIEW: user_progress_summary
-- ============================================
CREATE OR REPLACE VIEW user_progress_summary AS
SELECT 
    user_id,
    department_id,
    COUNT(*) as total_questions_answered,
    COUNT(*) FILTER (WHERE is_correct = true) as correct_answers,
    SUM(points_earned) as total_score,
    ROUND((COUNT(*) FILTER (WHERE is_correct = true)::numeric / NULLIF(COUNT(*), 0) * 100), 2) as accuracy_percentage,
    MIN(created_at) as first_activity,
    MAX(created_at) as last_activity
FROM user_progress
GROUP BY user_id, department_id;

-- ============================================
-- TABLE: user_pathway
-- ============================================
CREATE TABLE user_pathway (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    pathway_id UUID NOT NULL REFERENCES departments(id),
    pathway_name TEXT,
    assigned_by UUID REFERENCES auth.users(id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_current BOOLEAN DEFAULT true
);

-- ============================================
-- INDEXES for performance
-- ============================================
CREATE INDEX idx_dept_levels_dept_id ON dept_levels(dept_id);
CREATE INDEX idx_questions_type_id ON questions(type_id);
CREATE INDEX idx_questions_dept_id ON questions(dept_id);
CREATE INDEX idx_question_child_question_id ON question_child(question_id);
CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX idx_user_progress_dept_id ON user_progress(department_id);
CREATE INDEX idx_user_pathway_user_id ON user_pathway(user_id);
CREATE INDEX idx_user_pathway_pathway_id ON user_pathway(pathway_id);

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE departments IS 'Main departments/pathways table';
COMMENT ON TABLE dept_levels IS 'Child table storing individual levels for each department';
COMMENT ON TABLE questions IS 'Question bank with references to departments and types';
COMMENT ON TABLE question_child IS 'Child table for sub-questions (multi-part questions)';
COMMENT ON TABLE profiles IS 'User profile information';
COMMENT ON TABLE user_progress IS 'Tracks individual question answers with JSON storage';
COMMENT ON VIEW user_progress_summary IS 'Aggregated view of user progress statistics';
COMMENT ON TABLE user_pathway IS 'Tracks user enrollment in departments/pathways';

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Schema created successfully!';
    RAISE NOTICE 'Tables: departments, dept_levels, questions, question_types, question_child, profiles, user_progress, user_pathway';
    RAISE NOTICE 'Views: user_progress_summary';
END $$;
