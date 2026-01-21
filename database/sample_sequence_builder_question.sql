-- Sample Sequence Builder Question
-- Add this to your database after running add_sequence_builder_type.sql

-- First, get the sequence_builder type_id
-- You can run: SELECT id FROM quest_types WHERE name = 'sequence_builder';

-- Insert a sample sequence builder question
-- Replace 'your-dept-id-here' with an actual department ID from your database
INSERT INTO questions (
    id,
    type_id,
    category,
    subcategory,
    title,
    description,
    dept_id,
    difficulty,
    points,
    options
) VALUES (
    'qseq1111-1111-1111-1111-111111111111',
    (SELECT id FROM quest_types WHERE name = 'sequence_builder'),
    'General',
    'Mixed',
    'Arrange the daily routine in correct sequence',
    'Put these events in the order they happened during the day',
    'cccccccc-cccc-cccc-cccc-cccccccccccc', -- General Knowledge department
    'Easy',
    20,
    '[
        {"id": 1, "text": "7 o''clock- everyone lined up.", "correct_position": 7},
        {"id": 2, "text": "I had a special dinner party.", "correct_position": 2},
        {"id": 3, "text": "set up at 5 o''clock.", "correct_position": 3},
        {"id": 4, "text": "ate breakfast and get dressed.", "correct_position": 1},
        {"id": 5, "text": "Invited the guests.", "correct_position": 4},
        {"id": 6, "text": "further drove him to the parade.", "correct_position": 6},
        {"id": 7, "text": "The butler watched.", "correct_position": 8},
        {"id": 8, "text": "returned his umbrella and closed the door.", "correct_position": 9},
        {"id": 9, "text": "very tired but happy.", "correct_position": 5}
    ]'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- Verify the question was inserted
SELECT 
    q.id,
    q.title,
    qt.name as question_type,
    q.options
FROM questions q
JOIN quest_types qt ON q.type_id = qt.id
WHERE q.id = 'qseq1111-1111-1111-1111-111111111111';
