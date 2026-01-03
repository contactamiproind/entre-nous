-- ============================================
-- POPULATE QUESTION OPTIONS
-- ============================================
-- This script populates question_options table
-- from existing question_bank data

-- First, we need to link old question_bank IDs to new question IDs
-- Since we migrated questions but they got new IDs, we need to match by title

-- Populate MCQ options
INSERT INTO question_options (
  question_id,
  sub_question_number,
  option_text,
  is_correct
)
SELECT 
  q.id as question_id,
  ROW_NUMBER() OVER (PARTITION BY q.id ORDER BY opt_index) as sub_question_number,
  opt_value as option_text,
  (opt_value = qb.correct_answer) as is_correct
FROM question_bank qb
CROSS JOIN LATERAL (
  SELECT opt_index, opt_value
  FROM jsonb_array_elements_text(qb.options) WITH ORDINALITY AS t(opt_value, opt_index)
) AS opts
JOIN questions q ON q.title = qb.question_text
WHERE qb.question_type = 'multiple_choice'
  AND qb.options IS NOT NULL
ON CONFLICT DO NOTHING;

-- Verify
SELECT 'Question Options Created:' as info, COUNT(*) as count FROM question_options;

-- Sample data
SELECT qo.question_id, q.title, qo.option_text, qo.is_correct
FROM question_options qo
JOIN questions q ON q.id = qo.question_id
LIMIT 10;
