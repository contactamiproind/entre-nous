-- Update usr_progress score_earned to match the questions table points
-- This fixes the issue where users were awarded 100/50/25 points based on time
-- instead of the exact points defined in the question (e.g., 10).

UPDATE usr_progress AS up
SET score_earned = COALESCE(q.points, 10)
FROM questions AS q
WHERE up.question_id = q.id
  AND up.status = 'answered'
  -- Only update if the score is actually different (e.g. 100 vs 10)
  AND up.score_earned != COALESCE(q.points, 10);

-- Also fix any 0-point entries that should have points (if they were marked correct)
UPDATE usr_progress AS up
SET score_earned = COALESCE(q.points, 10)
FROM questions AS q
WHERE up.question_id = q.id
  AND up.status = 'answered'
  AND up.is_correct = true
  AND up.score_earned = 0;

-- Optional: Reset game scores if needed, but games might have variable scoring.
-- For now, this targets the main issue of inflated MCQ points.
