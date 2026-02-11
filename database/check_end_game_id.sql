-- Check details of the End Game assignment ID from logs
SELECT 
    ega.id as assignment_id,
    ega.user_id,
    ega.end_game_id,
    ega.completed_at,
    egc.level,
    egc.title
FROM end_game_assignments ega
JOIN end_game_configs egc ON egc.id = ega.end_game_id
WHERE ega.id = 'cacb7bbf-f16d-421e-8709-fb5d8655977d';

-- Check if there are other assignments for this user
SELECT 
    ega.id as assignment_id,
    ega.completed_at,
    egc.level,
    egc.title
FROM end_game_assignments ega
JOIN end_game_configs egc ON egc.id = ega.end_game_id
WHERE ega.user_id = '640164ea-3b53-49d3-a9dd-ef8632b1e2f6';
