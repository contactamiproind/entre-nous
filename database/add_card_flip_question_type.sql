-- Add memory_match to quest_types table
-- This is different from card_match (drag-and-drop buckets)
-- memory_match is a flip-card memory game where users find matching pairs

INSERT INTO quest_types (name) 
VALUES ('memory_match')
ON CONFLICT (name) DO NOTHING;

-- Card pairs will be stored in question_options table
-- Each pair will have two options with the same sub_question_number
-- Example:
-- sub_question_number = 1: First pair (2 cards)
-- sub_question_number = 2: Second pair (2 cards)
-- etc.
