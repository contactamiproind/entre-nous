-- Force assign Level 1 End Game to the user with email 'contactamiproind@gmail.com'

-- First, ensure Level 1 End Game config is active (just in case)
UPDATE end_game_configs SET is_active = true WHERE level = 1;

-- Get the End Game Config ID for Level 1
WITH active_game AS (
  SELECT id FROM end_game_configs WHERE level = 1 AND is_active = true LIMIT 1
),
target_user AS (
  SELECT id FROM auth.users WHERE email = 'contactamiproind@gmail.com' LIMIT 1
)
INSERT INTO end_game_assignments (user_id, end_game_id, assigned_at, score, completed_at)
SELECT 
  target_user.id,
  active_game.id,
  NOW(),
  0,
  NULL
FROM active_game, target_user
WHERE NOT EXISTS (
  SELECT 1 FROM end_game_assignments 
  WHERE user_id = target_user.id 
  AND end_game_id = active_game.id
);

-- Verify the assignment
SELECT * FROM end_game_assignments 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'contactamiproind@gmail.com');
