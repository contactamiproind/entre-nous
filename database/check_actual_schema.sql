-- Simplified schema check

-- Step 1: Check what tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Step 2: Check questions table structure
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'questions'
ORDER BY ordinal_position;

-- Step 3: Check departments table structure  
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'departments'
ORDER BY ordinal_position;

-- Step 4: Check sample questions data
SELECT * FROM questions LIMIT 3;

-- Step 5: Check Vision department
SELECT * FROM departments WHERE title = 'Vision';
