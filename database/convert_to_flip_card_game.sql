-- Update Card Match questions to use Card Flip (Memory Match) format
-- This changes from drag-and-drop buckets to flip card memory game

UPDATE questions
SET 
  options = '[]'::jsonb,  -- Empty options array for flip card games
  options_data = jsonb_build_array(
    -- Pair 1: Avocado Toast
    jsonb_build_object('sub_question_number', 1, 'option_text', '🥑 Avocado Toast', 'is_correct', true),
    jsonb_build_object('sub_question_number', 1, 'option_text', 'Healthy Breakfast', 'is_correct', true),
    
    -- Pair 2: Chick
    jsonb_build_object('sub_question_number', 2, 'option_text', '🐥 Chick', 'is_correct', true),
    jsonb_build_object('sub_question_number', 2, 'option_text', 'Baby Bird', 'is_correct', true),
    
    -- Pair 3: Cow
    jsonb_build_object('sub_question_number', 3, 'option_text', '🐮 Cow', 'is_correct', true),
    jsonb_build_object('sub_question_number', 3, 'option_text', 'Farm Animal', 'is_correct', true),
    
    -- Pair 4: Bear
    jsonb_build_object('sub_question_number', 4, 'option_text', '🐻 Bear', 'is_correct', true),
    jsonb_build_object('sub_question_number', 4, 'option_text', 'Forest Animal', 'is_correct', true),
    
    -- Pair 5: Zebra
    jsonb_build_object('sub_question_number', 5, 'option_text', '🦓 Zebra', 'is_correct', true),
    jsonb_build_object('sub_question_number', 5, 'option_text', 'Striped Animal', 'is_correct', true),
    
    -- Pair 6: Fox
    jsonb_build_object('sub_question_number', 6, 'option_text', '🦊 Fox', 'is_correct', true),
    jsonb_build_object('sub_question_number', 6, 'option_text', 'Clever Animal', 'is_correct', true)
  )
WHERE title = 'Card Match';

-- Verify the update
SELECT id, title, options_data
FROM questions
WHERE title = 'Card Match';
