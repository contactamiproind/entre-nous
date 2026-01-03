-- Update Values question to the synced Easy level ID (FIXED UUID)

UPDATE questions
SET level_id = 'da1599b2-a455-4802-b0f5-fafdde35fecd'
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
JOIN dept_levels dl ON q.level_id = dl.id
JOIN departments d ON dl.dept_id = d.id
WHERE q.id = '28c7f67c-5f45-49a2-8636-32991284e838';
