-- Solution: Add current_level column to usr_stat table
-- OR create a separate user_progress table

-- Option 1: Check if user_progress table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'user_progress';

-- Option 2: Create a user_progress summary table
CREATE TABLE IF NOT EXISTS user_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
  current_level INTEGER DEFAULT 1,
  total_score INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, department_id)
);

-- Insert initial progress for Vision pathway
INSERT INTO user_progress (user_id, department_id, current_level, total_score)
SELECT 
  'fe3c162a-0b43-4a79-bdff-d32234429781',
  id,
  2,  -- Set to 2 to unlock Mid level
  100
FROM departments
WHERE title = 'Vision'
ON CONFLICT (user_id, department_id) 
DO UPDATE SET current_level = 2, updated_at = NOW();

-- Insert for Values pathway
INSERT INTO user_progress (user_id, department_id, current_level, total_score)
SELECT 
  'fe3c162a-0b43-4a79-bdff-d32234429781',
  id,
  1,
  0
FROM departments
WHERE title = 'Values'
ON CONFLICT (user_id, department_id) 
DO UPDATE SET current_level = 1, updated_at = NOW();

-- Insert for Goals pathway
INSERT INTO user_progress (user_id, department_id, current_level, total_score)
SELECT 
  'fe3c162a-0b43-4a79-bdff-d32234429781',
  id,
  1,
  0
FROM departments
WHERE title = 'Goals'
ON CONFLICT (user_id, department_id) 
DO UPDATE SET current_level = 1, updated_at = NOW();

-- Verify
SELECT 
  up.user_id,
  d.title as pathway,
  up.current_level,
  up.total_score
FROM user_progress up
JOIN departments d ON up.department_id = d.id
WHERE up.user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781';
