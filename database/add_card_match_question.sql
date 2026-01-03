-- Insert a sample Card Match question for Level 2 (Orientation - Vision)
-- This question teaches the difference between Ease and Delight

INSERT INTO questions (
  level_id,
  question_type,
  question_text,
  options,
  correct_answer,
  points,
  created_at,
  updated_at
)
SELECT 
  l.id as level_id,
  'card_match' as question_type,
  'Match each action to either Ease or Delight' as question_text,
  jsonb_build_object(
    'buckets', jsonb_build_array(
      jsonb_build_object(
        'id', 'ease',
        'label', 'Ease',
        'icon', 'checklist',
        'color', 'blue'
      ),
      jsonb_build_object(
        'id', 'delight',
        'label', 'Delight',
        'icon', 'star',
        'color', 'gold'
      )
    ),
    'cards', jsonb_build_array(
      jsonb_build_object(
        'id', 'c1',
        'text', 'Clear process explanation',
        'correct_bucket', 'ease'
      ),
      jsonb_build_object(
        'id', 'c2',
        'text', 'Quick resolution of issue',
        'correct_bucket', 'ease'
      ),
      jsonb_build_object(
        'id', 'c3',
        'text', 'Thoughtful surprise element',
        'correct_bucket', 'delight'
      ),
      jsonb_build_object(
        'id', 'c4',
        'text', 'Memorable experience moment',
        'correct_bucket', 'delight'
      )
    )
  ) as options,
  null as correct_answer,
  50 as points,
  NOW() as created_at,
  NOW() as updated_at
FROM dept_levels l
JOIN departments d ON l.department_id = d.id
WHERE d.title = 'Orientation - Vision'
  AND l.level_number = 2
LIMIT 1;

-- Verify the question was inserted
SELECT 
  q.id,
  q.question_type,
  q.question_text,
  q.options,
  l.level_number,
  d.title as department
FROM questions q
JOIN dept_levels l ON q.level_id = l.id
JOIN departments d ON l.department_id = d.id
WHERE q.question_type = 'card_match'
ORDER BY q.created_at DESC
LIMIT 1;
