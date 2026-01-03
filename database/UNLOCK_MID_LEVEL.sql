-- Unlock Mid level by updating current_level to 2
-- Based on actual user_progress schema

UPDATE user_progress
SET current_level = 2  -- Unlock Mid level (level 2)
WHERE user_id = '443cc75c-9d06-4ca8-a9c6-f11d79d97487'
  AND current_pathway_id = '0630caa4-3087-4192-a6b4-20053c74e8f3'; -- Vision pathway

-- Verify the update
SELECT 
  user_id,
  current_pathway_id,
  current_level,
  total_score,
  created_at,
  updated_at
FROM user_progress
WHERE user_id = '443cc75c-9d06-4ca8-a9c6-f11d79d97487'
  AND current_pathway_id = '0630caa4-3087-4192-a6b4-20053c74e8f3';
