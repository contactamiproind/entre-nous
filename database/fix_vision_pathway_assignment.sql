-- Fix user pathway assignments: Change "Vision" to "Orientation - Vision"

-- First, check current assignments
SELECT 
  up.user_id,
  p.email,
  d.title as current_pathway,
  up.pathway_id
FROM user_pathway up
JOIN auth.users p ON up.user_id = p.id
JOIN departments d ON up.pathway_id = d.id
WHERE d.title LIKE '%Vision%';

-- Update assignments from "Vision" to "Orientation - Vision"
DO $$
DECLARE
  vision_id UUID;
  orientation_vision_id UUID;
BEGIN
  -- Get department IDs
  SELECT id INTO vision_id FROM departments WHERE title = 'Vision';
  SELECT id INTO orientation_vision_id FROM departments WHERE title = 'Orientation - Vision';
  
  -- Update user_pathway assignments
  UPDATE user_pathway
  SET pathway_id = orientation_vision_id,
      pathway_name = 'Orientation - Vision'
  WHERE pathway_id = vision_id;
  
  RAISE NOTICE 'Updated pathway assignments from Vision to Orientation - Vision';
END $$;

-- Verify the update
SELECT 
  up.user_id,
  p.email,
  d.title as updated_pathway,
  up.pathway_name
FROM user_pathway up
JOIN auth.users p ON up.user_id = p.id
JOIN departments d ON up.pathway_id = d.id
WHERE d.title LIKE '%Vision%';
