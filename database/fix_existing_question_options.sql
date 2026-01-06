-- Fix existing questions to have proper options format
-- This script converts options from plain string arrays to objects with is_correct flags
-- Run this in Supabase SQL Editor

-- Update questions where options is an array of strings
UPDATE questions
SET options = (
  SELECT jsonb_agg(
    jsonb_build_object(
      'text', option_text,
      'is_correct', option_text = correct_answer
    )
  )
  FROM jsonb_array_elements_text(options) AS option_text
)
WHERE 
  type_id IN (SELECT id FROM quest_types WHERE type IN ('mcq'))
  AND jsonb_typeof(options) = 'array'
  AND jsonb_array_length(options) > 0
  AND jsonb_typeof(options->0) = 'string';

-- Verify the update
SELECT 
  id,
  title,
  options,
  correct_answer
FROM questions
WHERE type_id IN (SELECT id FROM quest_types WHERE type IN ('mcq'))
LIMIT 10;
