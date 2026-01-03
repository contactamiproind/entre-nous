-- New Database Schema Implementation
-- Based on instructor's diagram
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. CREATE QUESTION_TYPES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS question_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. CREATE LEVELS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS levels (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  level_number INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  pathway_id UUID REFERENCES pathways(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(pathway_id, level_number)
);

-- ============================================
-- 3. CREATE QUESTION_BANK TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS question_bank (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  level_id UUID REFERENCES levels(id) ON DELETE CASCADE,
  question_type_id UUID REFERENCES question_types(id),
  question_text TEXT NOT NULL,
  options JSONB, -- For MCQ: ["Option A", "Option B", "Option C", "Option D"]
  correct_answer TEXT NOT NULL,
  points INTEGER DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. CREATE USER_PATHWAY TABLE (Junction Table)
-- ============================================

CREATE TABLE IF NOT EXISTS user_pathway (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  pathway_id UUID REFERENCES pathways(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  UNIQUE(user_id, pathway_id)
);

-- ============================================
-- 5. UPDATE USER_PROGRESS TABLE
-- ============================================

-- Add level_id column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_progress' AND column_name = 'level_id'
  ) THEN
    ALTER TABLE user_progress ADD COLUMN level_id UUID REFERENCES levels(id);
  END IF;
END $$;

-- ============================================
-- 6. ADD RLS POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE question_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_pathway ENABLE ROW LEVEL SECURITY;

-- Question Types: Everyone can read
DROP POLICY IF EXISTS "Anyone can view question types" ON question_types;
CREATE POLICY "Anyone can view question types"
ON question_types FOR SELECT
TO authenticated
USING (true);

-- Levels: Everyone can read
DROP POLICY IF EXISTS "Anyone can view levels" ON levels;
CREATE POLICY "Anyone can view levels"
ON levels FOR SELECT
TO authenticated
USING (true);

-- Question Bank: Everyone can read
DROP POLICY IF EXISTS "Anyone can view questions" ON question_bank;
CREATE POLICY "Anyone can view questions"
ON question_bank FOR SELECT
TO authenticated
USING (true);

-- User Pathway: Users can view and insert their own
DROP POLICY IF EXISTS "Users can view own pathways" ON user_pathway;
CREATE POLICY "Users can view own pathways"
ON user_pathway FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can enroll in pathways" ON user_pathway;
CREATE POLICY "Users can enroll in pathways"
ON user_pathway FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own pathways" ON user_pathway;
CREATE POLICY "Users can update own pathways"
ON user_pathway FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 7. CREATE INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_levels_pathway ON levels(pathway_id);
CREATE INDEX IF NOT EXISTS idx_question_bank_level ON question_bank(level_id);
CREATE INDEX IF NOT EXISTS idx_question_bank_type ON question_bank(question_type_id);
CREATE INDEX IF NOT EXISTS idx_user_pathway_user ON user_pathway(user_id);
CREATE INDEX IF NOT EXISTS idx_user_pathway_pathway ON user_pathway(pathway_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_level ON user_progress(level_id);
