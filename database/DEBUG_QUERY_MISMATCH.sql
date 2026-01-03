-- Check why the question isn't being returned by the app's query (FIXED)

-- 1. Verify question has correct level_id
SELECT 
  'QUESTION STATE' as info,
  id,
  title,
  level_id,
  dept_id,
  difficulty
FROM questions
WHERE id = '28c7f67c-5f45-49a2-8636-32991284e838';

-- 2. Check if there are ANY questions with this level_id
SELECT 
  'ALL QUESTIONS FOR THIS LEVEL' as info,
  id,
  title,
  level_id,
  difficulty
FROM questions
WHERE level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';

-- 3. Simulate the app's exact query
SELECT 
  'APP QUERY SIMULATION' as info,
  id,
  title,
  difficulty,
  level_id
FROM questions
WHERE level_id = 'f1e5977d-b3ff-4208-8b3c-cef90b7105d6';
