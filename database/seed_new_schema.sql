-- Seed Data for New Schema
-- Run this AFTER new_schema.sql

-- ============================================
-- 1. INSERT QUESTION TYPES
-- ============================================

INSERT INTO question_types (name, description) VALUES
('Multiple Choice', 'Questions with multiple options, one correct answer'),
('True/False', 'Questions with only true or false as answers'),
('Short Answer', 'Questions requiring brief text responses'),
('Essay', 'Questions requiring detailed written responses')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 2. INSERT LEVELS FOR EACH PATHWAY
-- ============================================

-- Get pathway IDs and create levels
DO $$
DECLARE
  pathway_rec RECORD;
BEGIN
  FOR pathway_rec IN SELECT id, name FROM pathways LOOP
    -- Create 5 levels for each pathway
    INSERT INTO levels (pathway_id, level_number, name, description) VALUES
    (pathway_rec.id, 1, pathway_rec.name || ' - Level 1', 'Beginner level'),
    (pathway_rec.id, 2, pathway_rec.name || ' - Level 2', 'Elementary level'),
    (pathway_rec.id, 3, pathway_rec.name || ' - Level 3', 'Intermediate level'),
    (pathway_rec.id, 4, pathway_rec.name || ' - Level 4', 'Advanced level'),
    (pathway_rec.id, 5, pathway_rec.name || ' - Level 5', 'Expert level')
    ON CONFLICT (pathway_id, level_number) DO NOTHING;
  END LOOP;
END $$;

-- ============================================
-- 3. INSERT SAMPLE QUESTIONS
-- ============================================

-- Get IDs for question types
DO $$
DECLARE
  mcq_type_id UUID;
  tf_type_id UUID;
  level_rec RECORD;
BEGIN
  -- Get question type IDs
  SELECT id INTO mcq_type_id FROM question_types WHERE name = 'Multiple Choice';
  SELECT id INTO tf_type_id FROM question_types WHERE name = 'True/False';
  
  -- Add sample questions for each level
  FOR level_rec IN SELECT id, level_number, name FROM levels LIMIT 10 LOOP
    -- MCQ Question
    INSERT INTO question_bank (
      level_id, 
      question_type_id, 
      question_text, 
      options, 
      correct_answer, 
      points
    ) VALUES (
      level_rec.id,
      mcq_type_id,
      'Sample question for ' || level_rec.name || '?',
      '["Option A", "Option B", "Option C", "Option D"]'::jsonb,
      'Option A',
      10 * level_rec.level_number
    );
    
    -- True/False Question
    INSERT INTO question_bank (
      level_id,
      question_type_id,
      question_text,
      options,
      correct_answer,
      points
    ) VALUES (
      level_rec.id,
      tf_type_id,
      'True or False: This is a sample question for ' || level_rec.name,
      '["True", "False"]'::jsonb,
      'True',
      5 * level_rec.level_number
    );
  END LOOP;
END $$;

-- ============================================
-- 4. VERIFY DATA
-- ============================================

-- Check question types
SELECT 'Question Types:' as info, COUNT(*) as count FROM question_types;

-- Check levels
SELECT 'Levels:' as info, COUNT(*) as count FROM levels;

-- Check questions
SELECT 'Questions:' as info, COUNT(*) as count FROM question_bank;

-- Show levels per pathway
SELECT 
  p.name as pathway,
  COUNT(l.id) as level_count
FROM pathways p
LEFT JOIN levels l ON p.id = l.pathway_id
GROUP BY p.name
ORDER BY p.name;
