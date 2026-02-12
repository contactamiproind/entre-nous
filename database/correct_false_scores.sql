-- Fix: Set score to 0 for incorrect answers
-- My previous script accidentally gave points to ALL answered questions.
-- This script reverts scores to 0 for any answer marked as incorrect.

UPDATE usr_progress
SET score_earned = 0
WHERE is_correct = false
  AND score_earned > 0;

-- Verify the result
SELECT count(*) as incorrect_with_points 
FROM usr_progress 
WHERE is_correct = false AND score_earned > 0;
