-- Move Values question to Orientation department Easy level
-- The app is loading level_id: f1e5977d-b3ff-4208-8b3c-cef90b7105d6 from "Orientation" dept

UPDATE questions
SET level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6',
    dept_id = (SELECT dept_id FROM dept_levels WHERE id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6')
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
