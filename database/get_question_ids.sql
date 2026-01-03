-- First, let's check the actual question IDs in the database
SELECT id, description, difficulty 
FROM questions 
ORDER BY created_at;

-- This will show you the correct UUIDs to use in the UPDATE statements
