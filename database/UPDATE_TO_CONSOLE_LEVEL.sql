-- Update Values question to EXACT level_id the app is querying
-- From console: f1e5977d-b3ff-4208-8b3c-cef90b7105d6

UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6'
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e838';

-- Verify the update
SELECT 
  'VERIFICATION' as info,
  q.id as question_id,
  q.title as question,
  q.level_id,
  dl.title as level_title,
  dl.level_number,
  d.title as department
FROM questions q
LEFT JOIN dept_levels dl ON q.level_id = dl.id
LEFT JOIN departments d ON dl.dept_id = d.id
WHERE q.id = '28c7f67c-5f45-49a2-8636-32991284e838';
