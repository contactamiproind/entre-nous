-- ============================================
-- SCHEMA REDESIGN - Following User Diagrams
-- ============================================
-- Keep Question and Department tables as designed
-- Simplify progress tracking

-- ============================================
-- 1. UPDATE USER_PROGRESS TABLE
-- ============================================

-- Drop existing user_progress if needed and recreate
DROP TABLE IF EXISTS user_progress CASCADE;

CREATE TABLE user_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  department_id UUID REFERENCES departments(id),
  question_id UUID REFERENCES questions(id),
  question_order INT, -- Order in which question was presented
  user_answer JSONB, -- User's answer stored as JSON
  is_correct BOOLEAN DEFAULT FALSE,
  points_earned INT DEFAULT 0,
  answered_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_user_progress_user ON user_progress(user_id);
CREATE INDEX idx_user_progress_dept ON user_progress(department_id);
CREATE INDEX idx_user_progress_question ON user_progress(question_id);

-- ============================================
-- 2. CREATE USER_PROGRESS_SUMMARY VIEW
-- ============================================

CREATE OR REPLACE VIEW user_progress_summary AS
SELECT 
  user_id,
  department_id,
  COUNT(DISTINCT question_id) as total_questions_answered,
  SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) as correct_answers,
  SUM(points_earned) as total_score,
  ROUND(
    (SUM(CASE WHEN is_correct THEN 1 ELSE 0 END)::DECIMAL / 
     NULLIF(COUNT(DISTINCT question_id), 0)) * 100, 
    2
  ) as accuracy_percentage,
  MAX(answered_at) as last_activity,
  MIN(answered_at) as first_activity
FROM user_progress
GROUP BY user_id, department_id;

-- ============================================
-- 3. UPDATE DEPARTMENTS TABLE
-- ============================================

-- Add levels JSON column if it doesn't exist
ALTER TABLE departments 
ADD COLUMN IF NOT EXISTS levels JSONB;

-- Example: Update a department with levels JSON
-- UPDATE departments 
-- SET levels = '[
--   {"level_number": 1, "title": "Basics", "category": "Foundation", "required_score": 70},
--   {"level_number": 2, "title": "Intermediate", "category": "Core", "required_score": 80},
--   {"level_number": 3, "title": "Advanced", "category": "Expert", "required_score": 90}
-- ]'::jsonb
-- WHERE name = 'Orientation';

-- ============================================
-- 4. KEEP dept_levels TABLE (as per diagram)
-- ============================================
-- dept_levels table already exists from previous migration
-- It has: dept_id, level_id, title, category, level_number

-- ============================================
-- 5. VERIFICATION QUERIES
-- ============================================

-- Check user_progress structure
SELECT 'User Progress Table:' as info, COUNT(*) as count FROM user_progress;

-- Check view
SELECT 'User Progress Summary View:' as info, COUNT(*) as count FROM user_progress_summary;

-- Check departments
SELECT 'Departments:' as info, COUNT(*) as count FROM departments;

-- Check dept_levels
SELECT 'Department Levels:' as info, COUNT(*) as count FROM department_levels;

-- Sample data from view
SELECT * FROM user_progress_summary LIMIT 5;
