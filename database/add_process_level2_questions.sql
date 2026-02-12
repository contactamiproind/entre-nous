-- Insert 5 questions for Process Department at Level 2
-- Department ID: a2e4dc11-044d-4276-8931-d686ccdc44ce (Process)

INSERT INTO questions (dept_id, level, title, description, options, correct_answer, points, type_id)
VALUES 
(
  'a2e4dc11-044d-4276-8931-d686ccdc44ce', -- Process Dept ID
  2,
  'Process Optimization',
  'What is the first step in optimizing a business process?',
  '[{"text": "Analyze current state", "is_correct": true}, {"text": "Buy new software", "is_correct": false}, {"text": "Fire employees", "is_correct": false}, {"text": "Change the logo", "is_correct": false}]',
  'Analyze current state',
  10,
  (SELECT id FROM quest_types WHERE type = 'mcq' LIMIT 1)
),
(
  'a2e4dc11-044d-4276-8931-d686ccdc44ce',
  2,
  'Standard Operating Procedures',
  'Why are SOPs important for a process?',
  '[{"text": "They look good on paper", "is_correct": false}, {"text": "Ensure consistency and quality", "is_correct": true}, {"text": "Increase complexity", "is_correct": false}, {"text": "Reduce transparency", "is_correct": false}]',
  'Ensure consistency and quality',
  10,
  (SELECT id FROM quest_types WHERE type = 'mcq' LIMIT 1)
),
(
  'a2e4dc11-044d-4276-8931-d686ccdc44ce',
  2,
  'Bottleneck Identification',
  'Which of the following indicates a bottleneck in a process?',
  '[{"text": "Smooth flow", "is_correct": false}, {"text": "Inventory buildup at one stage", "is_correct": true}, {"text": "High employee morale", "is_correct": false}, {"text": "Fast delivery times", "is_correct": false}]',
  'Inventory buildup at one stage',
  10,
  (SELECT id FROM quest_types WHERE type = 'mcq' LIMIT 1)
),
(
  'a2e4dc11-044d-4276-8931-d686ccdc44ce',
  2,
  'Feedback Loops',
  'What is the purpose of a feedback loop in a process?',
  '[{"text": "To create noise", "is_correct": false}, {"text": "To slow down production", "is_correct": false}, {"text": "To enable continuous improvement", "is_correct": true}, {"text": "To confuse customers", "is_correct": false}]',
  'To enable continuous improvement',
  10,
  (SELECT id FROM quest_types WHERE type = 'mcq' LIMIT 1)
),
(
  'a2e4dc11-044d-4276-8931-d686ccdc44ce',
  2,
  'Process Mapping',
  'Which tool is commonly used to visualize a process flow?',
  '[{"text": "Flowchart", "is_correct": true}, {"text": "Pie chart", "is_correct": false}, {"text": "Bar graph", "is_correct": false}, {"text": "Scatter plot", "is_correct": false}]',
  'Flowchart',
  10,
  (SELECT id FROM quest_types WHERE type = 'mcq' LIMIT 1)
);
