-- Update user to the Vision department where questions are
UPDATE user_pathway
SET pathway_id = '0630caa4-3087-4192-a6b4-20053c74e8f3',
    pathway_name = 'Vision'
WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781';

-- Verify the update
SELECT 
  u.email,
  d.id as pathway_id,
  d.title as pathway,
  up.pathway_name,
  up.is_current
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
WHERE u.id = 'fe3c162a-0b43-4a79-bdff-d32234429781';

-- Verify Vision department has the questions
SELECT 
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  dl.id as level_id,
  COUNT(q.id) as questions,
  STRING_AGG(q.title, ', ') as question_titles
FROM departments d
JOIN dept_levels dl ON d.id = dl.dept_id
LEFT JOIN questions q ON q.level_id = dl.id
WHERE d.id = '0630caa4-3087-4192-a6b4-20053c74e8f3'
GROUP BY d.title, dl.level_number, dl.title, dl.id
ORDER BY dl.level_number;
