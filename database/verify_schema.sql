-- Comprehensive Database Schema Verification
-- This script checks all tables have the correct columns according to the workflow

-- ============================================
-- 1. PROFILES TABLE
-- ============================================
SELECT 'PROFILES TABLE' as table_name;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- Expected columns:
-- ✓ id (uuid, primary key)
-- ✓ user_id (uuid, references auth.users)
-- ✓ email (text)
-- ✓ role (text) - 'user' or 'admin'

-- ============================================
-- 2. PATHWAYS TABLE
-- ============================================
SELECT 'PATHWAYS TABLE' as table_name;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'pathways'
ORDER BY ordinal_position;

-- Expected columns:
-- ✓ id (uuid, primary key)
-- ✓ name (text) - Communication, Creative, Ideation, Production
-- ✓ description (text)
-- ✓ created_at (timestamp)

-- ============================================
-- 3. LEVELS TABLE
-- ============================================
SELECT 'LEVELS TABLE' as table_name;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'levels'
ORDER BY ordinal_position;

-- Expected columns:
-- ✓ id (uuid, primary key)
-- ✓ pathway_id (uuid, references pathways)
-- ✓ level_number (integer) - 1, 2, 3, 4, 5
-- ✓ name (text) - Level name
-- ✓ description (text)

-- ============================================
-- 4. USER_PATHWAY TABLE
-- ============================================
SELECT 'USER_PATHWAY TABLE' as table_name;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_pathway'
ORDER BY ordinal_position;

-- Expected columns:
-- ✓ id (uuid, primary key)
-- ✓ user_id (uuid, references profiles)
-- ✓ pathway_id (uuid, references pathways)
-- ✓ pathway_name (text) - Denormalized for easy viewing
-- ✓ enrolled_at (timestamp)
-- ✓ is_current (boolean) - Only one can be true per user
-- ✓ completed (boolean)
-- ✓ completed_at (timestamp, nullable)

-- ============================================
-- 5. USER_PROGRESS TABLE
-- ============================================
SELECT 'USER_PROGRESS TABLE' as table_name;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_progress'
ORDER BY ordinal_position;

-- Expected columns:
-- ✓ id (uuid, primary key)
-- ✓ user_id (uuid, references profiles)
-- ✓ pathway_id (uuid, references pathways) - CRITICAL for pathway-specific progress
-- ✓ current_level (integer) - Current level in this pathway
-- ✓ current_score (integer) - Score in this pathway
-- ✓ orientation_completed (boolean, nullable)

-- ============================================
-- 6. QUESTION_BANK TABLE
-- ============================================
SELECT 'QUESTION_BANK TABLE' as table_name;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'question_bank'
ORDER BY ordinal_position;

-- Expected columns:
-- ✓ id (uuid, primary key)
-- ✓ level_id (uuid, references levels)
-- ✓ question_type_id (uuid, references question_types)
-- ✓ question_text (text)
-- ✓ options (jsonb or text) - Array of options
-- ✓ correct_answer (text)
-- ✓ created_at (timestamp)

-- ============================================
-- 7. QUESTION_TYPES TABLE
-- ============================================
SELECT 'QUESTION_TYPES TABLE' as table_name;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'question_types'
ORDER BY ordinal_position;

-- Expected columns:
-- ✓ id (uuid, primary key)
-- ✓ type_name (text) - MCQ, True/False, etc.
-- ✓ description (text)

-- ============================================
-- VERIFICATION SUMMARY
-- ============================================
SELECT 
  'VERIFICATION SUMMARY' as section,
  COUNT(DISTINCT table_name) as total_tables
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name IN (
  'profiles',
  'pathways', 
  'levels',
  'user_pathway',
  'user_progress',
  'question_bank',
  'question_types'
);

-- ============================================
-- CHECK FOR MISSING CRITICAL COLUMNS
-- ============================================

-- Check if user_progress has pathway_id (CRITICAL!)
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'user_progress' 
      AND column_name = 'pathway_id'
    ) 
    THEN '✓ user_progress.pathway_id EXISTS'
    ELSE '✗ MISSING: user_progress.pathway_id - RUN make_progress_pathway_specific.sql!'
  END as pathway_specific_check;

-- Check if user_pathway has is_current
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'user_pathway' 
      AND column_name = 'is_current'
    ) 
    THEN '✓ user_pathway.is_current EXISTS'
    ELSE '✗ MISSING: user_pathway.is_current - RUN add_current_pathway.sql!'
  END as current_pathway_check;

-- Check if user_pathway has pathway_name
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'user_pathway' 
      AND column_name = 'pathway_name'
    ) 
    THEN '✓ user_pathway.pathway_name EXISTS'
    ELSE '✗ MISSING: user_pathway.pathway_name - RUN add_pathway_name_column.sql!'
  END as pathway_name_check;

-- ============================================
-- LIST ALL TABLES IN DATABASE
-- ============================================
SELECT 
  'ALL TABLES IN DATABASE' as section,
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns c WHERE c.table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;
