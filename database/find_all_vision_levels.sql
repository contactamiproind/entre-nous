-- Find ALL dept_levels for Vision department (0630caa4...)
SELECT 
  dl.id as level_id,
  dl.level_number,
  dl.title,
  dl.created_at,
  COUNT(q.id) as questions
FROM dept_levels dl
LEFT JOIN questions q ON q.level_id = dl.id
WHERE dl.dept_id = '0630caa4-3087-4192-a6b4-20053c74e8f3'
GROUP BY dl.id, dl.level_number, dl.title, dl.created_at
ORDER BY dl.created_at, dl.level_number;

-- Check if f1ac997d... exists in dept_levels at all
SELECT 
  dl.id,
  dl.dept_id,
  d.title as department,
  dl.level_number,
  dl.title as level_title,
  dl.created_at
FROM dept_levels dl
LEFT JOIN departments d ON dl.dept_id = d.id
WHERE dl.id = 'f1ac997d-b3ff-4208-8b3c-cef90b7105d6';

-- Delete OLD/DUPLICATE dept_levels for Vision and keep only the latest ones
-- First, let's see which ones to delete
SELECT 
  'LEVELS TO DELETE' as action,
  dl.id,
  dl.level_number,
  dl.title,
  dl.created_at
FROM dept_levels dl
WHERE dl.dept_id = '0630caa4-3087-4192-a6b4-20053c74e8f3'
  AND dl.id NOT IN ('69748822-e974-4653-bd02-cba2ef9808d9', '2b33458d-c960-4d88-ac18-9d9c22eca62e')
ORDER BY dl.created_at;
