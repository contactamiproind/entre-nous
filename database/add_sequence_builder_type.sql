-- Add sequence_builder to quest_types table
-- This is a new interactive game type where users drag numbers to match sentences in correct order
-- Similar to arranging events in chronological sequence

-- First, we need to alter the CHECK constraint on quest_types table to allow sequence_builder
-- Note: This requires dropping and recreating the constraint
ALTER TABLE quest_types DROP CONSTRAINT IF EXISTS quest_types_name_check;
ALTER TABLE quest_types ADD CONSTRAINT quest_types_name_check 
  CHECK (name IN ('mcq', 'match_following', 'fill_blank', 'card_match', 'scenario_decision', 'memory_match', 'sequence_builder'));

-- Insert the new quest type
INSERT INTO quest_types (name) 
VALUES ('sequence_builder')
ON CONFLICT (name) DO NOTHING;

-- Sample sequence_builder question
-- The options field stores an array of sentence objects with their correct positions
-- Each sentence has: id, text, and correct_position

-- Example data structure:
-- [
--   {"id": 1, "text": "7 o'clock- everyone lined up.", "correct_position": 1},
--   {"id": 2, "text": "I had a special dinner party.", "correct_position": 2},
--   {"id": 3, "text": "set up at 5 o'clock.", "correct_position": 3},
--   {"id": 4, "text": "ate breakfast and get dressed.", "correct_position": 4},
--   {"id": 5, "text": "Invited the guests.", "correct_position": 5},
--   {"id": 6, "text": "further drove him to the parade.", "correct_position": 6},
--   {"id": 7, "text": "The butler watched.", "correct_position": 7},
--   {"id": 8, "text": "returned his umbrella and closed the door.", "correct_position": 8},
--   {"id": 9, "text": "very tired but happy.", "correct_position": 9}
-- ]
