-- ============================================
-- DATABASE SCHEMA RESTRUCTURING
-- ============================================
-- New schema based on updated design
-- Question table with proper structure
-- Department table with levels as child table

-- ============================================
-- 1. CREATE NEW TABLES
-- ============================================

-- Question Types Reference Table
CREATE TABLE IF NOT EXISTS question_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE, -- 'mcq', 'match_following', 'fill_blank'
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insert default question types
INSERT INTO question_types (name) VALUES 
  ('mcq'),
  ('match_following'),
  ('fill_blank')
ON CONFLICT (name) DO NOTHING;

-- New Questions Table
CREATE TABLE IF NOT EXISTS questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type_id UUID REFERENCES question_types(id),
  category TEXT,
  subcategory TEXT,
  title TEXT NOT NULL,
  description TEXT,
  tags TEXT[],
  department_id UUID REFERENCES departments(id),
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  points INT DEFAULT 10,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Question Options (for MCQ and Match Following)
CREATE TABLE IF NOT EXISTS question_options (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
  sub_question_number INT DEFAULT 1,
  option_text TEXT NOT NULL,
  is_correct BOOLEAN DEFAULT FALSE,
  match_pair_left TEXT, -- for match following
  match_pair_right TEXT, -- for match following
  created_at TIMESTAMP DEFAULT NOW()
);

-- Update Departments Table (add new fields)
ALTER TABLE departments 
ADD COLUMN IF NOT EXISTS title TEXT,
ADD COLUMN IF NOT EXISTS category TEXT,
ADD COLUMN IF NOT EXISTS subcategory TEXT,
ADD COLUMN IF NOT EXISTS tags JSONB;

-- Update name to title if title is null
UPDATE departments SET title = name WHERE title IS NULL;

-- Department Levels (already exists as department_levels, just verify structure)
-- This table already exists from previous migration

-- ============================================
-- 2. CREATE INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_questions_department ON questions(department_id);
CREATE INDEX IF NOT EXISTS idx_questions_type ON questions(type_id);
CREATE INDEX IF NOT EXISTS idx_questions_category ON questions(category);
CREATE INDEX IF NOT EXISTS idx_question_options_question ON question_options(question_id);

-- ============================================
-- 3. MIGRATE EXISTING DATA
-- ============================================

-- Migrate from old question_bank to new questions table
-- This will preserve existing orientation questions
INSERT INTO questions (
  type_id,
  title,
  description,
  department_id,
  points
)
SELECT 
  (SELECT id FROM question_types WHERE name = 
    CASE 
      WHEN qb.question_type = 'multiple_choice' THEN 'mcq'
      WHEN qb.question_type = 'match_following' THEN 'match_following'
      ELSE 'mcq'
    END
  ),
  qb.question_text,
  qb.question_text, -- use question_text as description for now
  (SELECT id FROM departments WHERE name = 'Orientation' LIMIT 1),
  10 -- default points
FROM question_bank qb
ON CONFLICT DO NOTHING;

-- Migrate MCQ options
-- NOTE: Skipping for now - will need to be done manually or with updated logic
-- since question IDs changed during migration
/*
INSERT INTO question_options (
  question_id,
  option_text,
  is_correct
)
SELECT 
  qb.id,
  opt,
  (opt = qb.correct_answer)
FROM question_bank qb,
LATERAL jsonb_array_elements_text(qb.options) AS opt
WHERE qb.question_type = 'multiple_choice'
  AND qb.options IS NOT NULL
ON CONFLICT DO NOTHING;
*/

-- ============================================
-- 4. VERIFICATION QUERIES
-- ============================================

-- Check question types
SELECT 'Question Types:' as info, COUNT(*) as count FROM question_types;

-- Check questions
SELECT 'Questions:' as info, COUNT(*) as count FROM questions;

-- Check question options
SELECT 'Question Options:' as info, COUNT(*) as count FROM question_options;

-- Check departments
SELECT 'Departments:' as info, COUNT(*) as count FROM departments;

-- Check department levels
SELECT 'Department Levels:' as info, COUNT(*) as count FROM department_levels;

-- Sample data
SELECT q.id, q.title, qt.name as type, q.category, d.title as department
FROM questions q
LEFT JOIN question_types qt ON q.type_id = qt.id
LEFT JOIN departments d ON q.department_id = d.id
LIMIT 5;
