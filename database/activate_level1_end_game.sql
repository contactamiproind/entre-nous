-- Re-activate the Level 1 End Game "Birthday Party"
UPDATE end_game_configs
SET is_active = true
WHERE level = 1
  AND is_active = false
  AND name = 'Birthday Party';

-- Verify the update
SELECT * FROM end_game_configs WHERE level = 1;

-- Also check for any existing assignment for the user
-- (Using a recent user ID from logs if needed, but this check is global for now)
-- SELECT * FROM end_game_assignments WHERE end_game_id IN (SELECT id FROM end_game_configs WHERE level = 1);
