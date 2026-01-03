-- Manually assign contactam1pro1nd@gmail.com to Orientation-Values department

-- Get the user ID first
WITH contact_user AS (
  SELECT id FROM auth.users WHERE email = 'contactam1pro1nd@gmail.com'
)

-- Insert into user_pathway
INSERT INTO user_pathway (user_id, pathway_id, is_current)
SELECT 
  contact_user.id,
  '32d2764f-ed76-40db-8886-bcf5923f91a1', -- Orientation-Values department ID
  true
FROM contact_user
ON CONFLICT (user_id, pathway_id) 
DO UPDATE SET is_current = true;

-- Insert into user_progress
WITH contact_user AS (
  SELECT id FROM auth.users WHERE email = 'contactam1pro1nd@gmail.com'
)
INSERT INTO user_progress (user_id, current_pathway_id, current_level, total_score)
SELECT 
  contact_user.id,
  '32d2764f-ed76-40db-8886-bcf5923f91a1', -- Orientation-Values department ID
  1, -- Start at level 1
  0  -- Initial score
FROM contact_user
ON CONFLICT (user_id, current_pathway_id) 
DO UPDATE SET 
  current_level = 1,
  total_score = 0;

-- Verify the assignment
SELECT 
  'VERIFICATION' as info,
  u.email,
  d.title as department,
  up.is_current,
  prog.current_level
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
LEFT JOIN user_progress prog ON prog.user_id = u.id AND prog.current_pathway_id = d.id
WHERE u.email = 'contactam1pro1nd@gmail.com';
