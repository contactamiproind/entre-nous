-- Check the profile level and end game status for the user
-- Fixed: Uses user_id instead of id
SELECT 
    p.user_id, 
    p.full_name, 
    p.level,
    count(ega.id) as complete_end_games
FROM profiles p
LEFT JOIN end_game_assignments ega ON p.user_id = ega.user_id AND ega.completed_at IS NOT NULL
GROUP BY p.user_id, p.full_name, p.level;
