-- Update THIS SPECIFIC USER to Orientation - Vision
DO $$
DECLARE
  orientation_vision_id UUID;
BEGIN
  -- Get Orientation - Vision department ID
  SELECT id INTO orientation_vision_id FROM departments WHERE title = 'Orientation - Vision';
  
  -- Update this user's pathway assignment
  UPDATE user_pathway
  SET pathway_id = orientation_vision_id,
      pathway_name = 'Orientation - Vision'
  WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781';
  
  RAISE NOTICE 'Updated user fe3c162a to Orientation - Vision';
  RAISE NOTICE 'New pathway_id: %', orientation_vision_id;
END $$;

-- Verify the update
SELECT 
  u.email,
  d.title as pathway,
  up.pathway_name,
  up.is_current
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
JOIN departments d ON up.pathway_id = d.id
WHERE u.id = 'fe3c162a-0b43-4a79-bdff-d32234429781';
