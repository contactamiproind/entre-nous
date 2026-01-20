-- Fix Card Match question options that are empty
-- This updates the existing Card Match questions to have the proper buckets and cards structure

UPDATE questions
SET options = jsonb_build_object(
  'buckets', jsonb_build_array(
    jsonb_build_object('id', 'ease', 'label', 'Ease', 'icon', 'checklist', 'color', 'blue'),
    jsonb_build_object('id', 'delight', 'label', 'Delight', 'icon', 'star', 'color', 'gold')
  ),
  'cards', jsonb_build_array(
    jsonb_build_object('id', 'c1', 'text', 'Clear process explanation', 'correct_bucket', 'ease'),
    jsonb_build_object('id', 'c2', 'text', 'Quick resolution of issue', 'correct_bucket', 'ease'),
    jsonb_build_object('id', 'c3', 'text', 'Thoughtful surprise element', 'correct_bucket', 'delight'),
    jsonb_build_object('id', 'c4', 'text', 'Memorable experience moment', 'correct_bucket', 'delight')
  )
)
WHERE title = 'Card Match'
  AND (options = '[]'::jsonb OR options IS NULL);

-- Verify the update
SELECT id, title, options
FROM questions
WHERE title = 'Card Match';
