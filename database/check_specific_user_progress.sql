-- Check if user 2073ec2e-a943-4ab3-b5e3-d71c4945dc3b has any End Game assignment
SELECT * FROM end_game_assignments 
WHERE user_id = '2073ec2e-a943-4ab3-b5e3-d71c4945dc3b';

-- Check all Level 1 Depts for user
-- (Orientation, Process, SOP, Production)
SELECT * FROM usr_dept
WHERE user_id = '2073ec2e-a943-4ab3-b5e3-d71c4945dc3b';
