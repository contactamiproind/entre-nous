-- Simplified approach: Check if record exists, then update or insert

-- Step 1: Check current state
SELECT 
  up.id,
  up.user_id,
  up.current_pathway_id,
  up.current_level,
  d.title as pathway_title
FROM user_progress up
LEFT JOIN departments d ON up.current_pathway_id = d.id
WHERE up.user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781';

-- Step 2: Try to UPDATE first
UPDATE user_progress
SET current_level = 2,
    updated_at = NOW()
WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781'
  AND current_pathway_id = '0630caa4-3087-4192-a6b4-20053c74e8f3';

-- Step 3: If UPDATE affected 0 rows, run this INSERT
-- (Only run this if the UPDATE above returned "0 rows affected")
INSERT INTO user_progress (user_id, current_pathway_id, current_level, total_score, completed_assignments)
VALUES (
  'fe3c162a-0b43-4a79-bdff-d32234429781',
  '0630caa4-3087-4192-a6b4-20053c74e8f3',
  2,
  100,
  0
);

-- Step 4: Verify the change
SELECT 
  up.current_level,
  up.total_score,
  d.title as pathway_title
FROM user_progress up
LEFT JOIN departments d ON up.current_pathway_id = d.id
WHERE up.user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781'
  AND up.current_pathway_id = '0630caa4-3087-4192-a6b4-20053c74e8f3';
