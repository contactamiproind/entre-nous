-- ============================================
-- Entre Nous Quiz Application - Seed Data
-- ============================================
-- Sample data for development and testing
-- Run this AFTER schema.sql
-- ============================================

-- ============================================
-- SEED: quest_types
-- ============================================
-- Insert question types

INSERT INTO quest_types (id, name) VALUES
    ('11111111-1111-1111-1111-111111111111', 'mcq'),
    ('22222222-2222-2222-2222-222222222222', 'match_following'),
    ('33333333-3333-3333-3333-333333333333', 'fill_blank')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- SEED: departments
-- ============================================
-- Insert sample departments

INSERT INTO departments (id, title, description, category, subcategory, levels) VALUES
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'French Language Basics',
        'Learn fundamental French language skills including vocabulary, grammar, and conversation',
        'Language',
        'French',
        '[
            {"level": 1, "name": "Beginner", "description": "Basic vocabulary and phrases"},
            {"level": 2, "name": "Intermediate", "description": "Grammar and sentence construction"},
            {"level": 3, "name": "Advanced", "description": "Conversation and fluency"}
        ]'::jsonb
    ),
    (
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'Mathematics Fundamentals',
        'Core mathematics concepts including arithmetic, algebra, and geometry',
        'Mathematics',
        'General',
        '[
            {"level": 1, "name": "Easy", "description": "Basic arithmetic"},
            {"level": 2, "name": "Medium", "description": "Algebra and equations"},
            {"level": 3, "name": "Hard", "description": "Advanced problem solving"}
        ]'::jsonb
    ),
    (
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
        'General Knowledge',
        'Test your knowledge across various topics including history, science, and culture',
        'General',
        'Mixed',
        '[
            {"level": 1, "name": "Easy", "description": "Common knowledge"},
            {"level": 2, "name": "Medium", "description": "Intermediate facts"},
            {"level": 3, "name": "Hard", "description": "Expert knowledge"}
        ]'::jsonb
    )
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SEED: questions (French Language)
-- ============================================

-- French MCQ Questions
INSERT INTO questions (id, type_id, category, subcategory, title, description, dept_id, difficulty, points) VALUES
    (
        'q1111111-1111-1111-1111-111111111111',
        '11111111-1111-1111-1111-111111111111',
        'Language',
        'French',
        'What is "Hello" in French?',
        'Basic French greeting',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'Easy',
        10
    ),
    (
        'q2222222-2222-2222-2222-222222222222',
        '11111111-1111-1111-1111-111111111111',
        'Language',
        'French',
        'How do you say "Thank you" in French?',
        'Common French phrase',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'Easy',
        10
    ),
    (
        'q3333333-3333-3333-3333-333333333333',
        '11111111-1111-1111-1111-111111111111',
        'Language',
        'French',
        'What does "Au revoir" mean?',
        'French farewell phrase',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'Easy',
        10
    ),
    (
        'q4444444-4444-4444-4444-444444444444',
        '22222222-2222-2222-2222-222222222222',
        'Language',
        'French',
        'Match the French words with their English meanings',
        'Vocabulary matching exercise',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'Mid',
        15
    ),
    (
        'q5555555-5555-5555-5555-555555555555',
        '11111111-1111-1111-1111-111111111111',
        'Language',
        'French',
        'Which article is used for feminine nouns in French?',
        'French grammar - articles',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'Mid',
        15
    )
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SEED: question_options (French Language)
-- ============================================

-- Options for Q1: What is "Hello" in French?
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct) VALUES
    ('q1111111-1111-1111-1111-111111111111', 1, 'Bonjour', true),
    ('q1111111-1111-1111-1111-111111111111', 1, 'Au revoir', false),
    ('q1111111-1111-1111-1111-111111111111', 1, 'Merci', false),
    ('q1111111-1111-1111-1111-111111111111', 1, 'Oui', false)
ON CONFLICT DO NOTHING;

-- Options for Q2: How do you say "Thank you" in French?
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct) VALUES
    ('q2222222-2222-2222-2222-222222222222', 1, 'Merci', true),
    ('q2222222-2222-2222-2222-222222222222', 1, 'Bonjour', false),
    ('q2222222-2222-2222-2222-222222222222', 1, 'Pardon', false),
    ('q2222222-2222-2222-2222-222222222222', 1, 'Salut', false)
ON CONFLICT DO NOTHING;

-- Options for Q3: What does "Au revoir" mean?
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct) VALUES
    ('q3333333-3333-3333-3333-333333333333', 1, 'Goodbye', true),
    ('q3333333-3333-3333-3333-333333333333', 1, 'Hello', false),
    ('q3333333-3333-3333-3333-333333333333', 1, 'Please', false),
    ('q3333333-3333-3333-3333-333333333333', 1, 'Thank you', false)
ON CONFLICT DO NOTHING;

-- Options for Q4: Match the French words (Match Following)
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct, match_pair_left, match_pair_right) VALUES
    ('q4444444-4444-4444-4444-444444444444', 1, 'Chat - Cat', true, 'Chat', 'Cat'),
    ('q4444444-4444-4444-4444-444444444444', 2, 'Chien - Dog', true, 'Chien', 'Dog'),
    ('q4444444-4444-4444-4444-444444444444', 3, 'Maison - House', true, 'Maison', 'House'),
    ('q4444444-4444-4444-4444-444444444444', 4, 'Livre - Book', true, 'Livre', 'Book')
ON CONFLICT DO NOTHING;

-- Options for Q5: Which article is used for feminine nouns?
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct) VALUES
    ('q5555555-5555-5555-5555-555555555555', 1, 'La', true),
    ('q5555555-5555-5555-5555-555555555555', 1, 'Le', false),
    ('q5555555-5555-5555-5555-555555555555', 1, 'Les', false),
    ('q5555555-5555-5555-5555-555555555555', 1, 'Un', false)
ON CONFLICT DO NOTHING;

-- ============================================
-- SEED: questions (Mathematics)
-- ============================================

INSERT INTO questions (id, type_id, category, subcategory, title, description, dept_id, difficulty, points) VALUES
    (
        'q6666666-6666-6666-6666-666666666666',
        '11111111-1111-1111-1111-111111111111',
        'Mathematics',
        'General',
        'What is 15 + 27?',
        'Basic addition',
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'Easy',
        10
    ),
    (
        'q7777777-7777-7777-7777-777777777777',
        '11111111-1111-1111-1111-111111111111',
        'Mathematics',
        'General',
        'What is 8 × 7?',
        'Multiplication',
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'Easy',
        10
    ),
    (
        'q8888888-8888-8888-8888-888888888888',
        '11111111-1111-1111-1111-111111111111',
        'Mathematics',
        'General',
        'Solve for x: 2x + 5 = 15',
        'Simple algebra',
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'Mid',
        15
    ),
    (
        'q9999999-9999-9999-9999-999999999999',
        '11111111-1111-1111-1111-111111111111',
        'Mathematics',
        'General',
        'What is the area of a circle with radius 5?',
        'Geometry - circle area',
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'Hard',
        20
    )
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SEED: question_options (Mathematics)
-- ============================================

-- Options for Q6: What is 15 + 27?
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct) VALUES
    ('q6666666-6666-6666-6666-666666666666', 1, '42', true),
    ('q6666666-6666-6666-6666-666666666666', 1, '32', false),
    ('q6666666-6666-6666-6666-666666666666', 1, '52', false),
    ('q6666666-6666-6666-6666-666666666666', 1, '40', false)
ON CONFLICT DO NOTHING;

-- Options for Q7: What is 8 × 7?
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct) VALUES
    ('q7777777-7777-7777-7777-777777777777', 1, '56', true),
    ('q7777777-7777-7777-7777-777777777777', 1, '54', false),
    ('q7777777-7777-7777-7777-777777777777', 1, '64', false),
    ('q7777777-7777-7777-7777-777777777777', 1, '48', false)
ON CONFLICT DO NOTHING;

-- Options for Q8: Solve for x: 2x + 5 = 15
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct) VALUES
    ('q8888888-8888-8888-8888-888888888888', 1, '5', true),
    ('q8888888-8888-8888-8888-888888888888', 1, '10', false),
    ('q8888888-8888-8888-8888-888888888888', 1, '7', false),
    ('q8888888-8888-8888-8888-888888888888', 1, '3', false)
ON CONFLICT DO NOTHING;

-- Options for Q9: Area of circle with radius 5
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct) VALUES
    ('q9999999-9999-9999-9999-999999999999', 1, '78.54', true),
    ('q9999999-9999-9999-9999-999999999999', 1, '31.42', false),
    ('q9999999-9999-9999-9999-999999999999', 1, '25', false),
    ('q9999999-9999-9999-9999-999999999999', 1, '157.08', false)
ON CONFLICT DO NOTHING;

-- ============================================
-- SEED: questions (General Knowledge)
-- ============================================

INSERT INTO questions (id, type_id, category, subcategory, title, description, dept_id, difficulty, points) VALUES
    (
        'qa111111-1111-1111-1111-111111111111',
        '11111111-1111-1111-1111-111111111111',
        'General',
        'Mixed',
        'What is the capital of France?',
        'Geography question',
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
        'Easy',
        10
    ),
    (
        'qa222222-2222-2222-2222-222222222222',
        '11111111-1111-1111-1111-111111111111',
        'General',
        'Mixed',
        'Who painted the Mona Lisa?',
        'Art history question',
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
        'Easy',
        10
    ),
    (
        'qa333333-3333-3333-3333-333333333333',
        '11111111-1111-1111-1111-111111111111',
        'General',
        'Mixed',
        'What year did World War II end?',
        'History question',
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
        'Mid',
        15
    ),
    (
        'qa444444-4444-4444-4444-444444444444',
        '22222222-2222-2222-2222-222222222222',
        'General',
        'Mixed',
        'Match the countries with their capitals',
        'Geography matching',
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
        'Mid',
        15
    )
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SEED: question_options (General Knowledge)
-- ============================================

-- Options for QA1: Capital of France
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct) VALUES
    ('qa111111-1111-1111-1111-111111111111', 1, 'Paris', true),
    ('qa111111-1111-1111-1111-111111111111', 1, 'London', false),
    ('qa111111-1111-1111-1111-111111111111', 1, 'Berlin', false),
    ('qa111111-1111-1111-1111-111111111111', 1, 'Madrid', false)
ON CONFLICT DO NOTHING;

-- Options for QA2: Who painted Mona Lisa
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct) VALUES
    ('qa222222-2222-2222-2222-222222222222', 1, 'Leonardo da Vinci', true),
    ('qa222222-2222-2222-2222-222222222222', 1, 'Michelangelo', false),
    ('qa222222-2222-2222-2222-222222222222', 1, 'Pablo Picasso', false),
    ('qa222222-2222-2222-2222-222222222222', 1, 'Vincent van Gogh', false)
ON CONFLICT DO NOTHING;

-- Options for QA3: When did WWII end
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct) VALUES
    ('qa333333-3333-3333-3333-333333333333', 1, '1945', true),
    ('qa333333-3333-3333-3333-333333333333', 1, '1944', false),
    ('qa333333-3333-3333-3333-333333333333', 1, '1946', false),
    ('qa333333-3333-3333-3333-333333333333', 1, '1943', false)
ON CONFLICT DO NOTHING;

-- Options for QA4: Match countries with capitals
INSERT INTO question_options (question_id, sub_question_number, option_text, is_correct, match_pair_left, match_pair_right) VALUES
    ('qa444444-4444-4444-4444-444444444444', 1, 'Japan - Tokyo', true, 'Japan', 'Tokyo'),
    ('qa444444-4444-4444-4444-444444444444', 2, 'Italy - Rome', true, 'Italy', 'Rome'),
    ('qa444444-4444-4444-4444-444444444444', 3, 'Egypt - Cairo', true, 'Egypt', 'Cairo'),
    ('qa444444-4444-4444-4444-444444444444', 4, 'Brazil - Brasília', true, 'Brazil', 'Brasília')
ON CONFLICT DO NOTHING;

-- ============================================
-- SEED DATA COMPLETE
-- ============================================

-- Display summary
SELECT 'Seed data inserted successfully!' as status;

SELECT 
    'Summary:' as info,
    (SELECT COUNT(*) FROM quest_types) as question_types,
    (SELECT COUNT(*) FROM departments) as departments,
    (SELECT COUNT(*) FROM questions) as questions,
    (SELECT COUNT(*) FROM question_options) as question_options;

-- Display departments with question counts
SELECT 
    d.title as department,
    d.category,
    COUNT(q.id) as question_count
FROM departments d
LEFT JOIN questions q ON d.id = q.dept_id
GROUP BY d.id, d.title, d.category
ORDER BY d.title;
