-- Fix Mid level - assign to the exact level ID app is querying
UPDATE questions
SET level_id = '2b33458d-c960-4d88-ac18-9d9c22eca62e',
    dept_id = '0630caa4-3087-4192-a6b4-20053c74e8f3',
    difficulty = 'medium'
WHERE title = 'Card Match'
  AND description LIKE '%Ease vs Delight%';

-- Verify
SELECT 
  q.title,
  q.description,
  q.level_id,
  dl.title as level_title,
  d.title as department
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
JOIN departments d ON dl.dept_id = d.id
WHERE q.title = 'Card Match'
  AND q.description LIKE '%Ease vs Delight%';
