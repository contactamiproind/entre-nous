-- Check how questions are linked and if they reference Vision levels

-- Step 1: Check questions table structure
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'questions'
ORDER BY ordinal_position;

-- Step 2: Check sample questions
SELECT * FROM questions LIMIT 3;

-- Step 3: Check if questions have department_id or level_id
SELECT 
  COUNT(*) as total_questions,
  COUNT(DISTINCT department_id) as departments_with_questions,
  COUNT(DISTINCT level_id) as levels_with_questions
FROM questions;

-- Step 4: Check questions for Vision department (if department_id exists)
SELECT 
  q.*
FROM questions q
WHERE q.department_id = (SELECT id FROM departments WHERE title = 'Vision')
LIMIT 5;
