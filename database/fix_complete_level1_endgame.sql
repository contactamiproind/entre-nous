-- Manually mark the Level 1 End Game assignment as completed for the user
-- using the specific assignment ID from logs: cacb7bbf-f16d-421e-8709-fb5d8655977d
UPDATE end_game_assignments
SET 
  completed_at = NULL,
  score = 0
WHERE id = 'cacb7bbf-f16d-421e-8709-fb5d8655977d';

-- Verify the update
SELECT * FROM end_game_assignments 
WHERE id = 'cacb7bbf-f16d-421e-8709-fb5d8655977d';
