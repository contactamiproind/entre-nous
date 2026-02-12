-- Reset Orientation Progress for 0-point questions
-- This deletes entries where the user got 0 points, allowing them to retake the question.
-- This is useful if the user believes they were correct but the system recorded 0 due to a bug.

DELETE FROM usr_progress
WHERE score_earned = 0
  AND category = 'Orientation';

-- Verify deletion
SELECT count(*) as remaining_zero_scores_orientation
FROM usr_progress
WHERE score_earned = 0 AND category = 'Orientation';
