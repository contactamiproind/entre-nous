-- Manually assign pathway to user (bypass RLS issues)
-- Run this in Supabase SQL Editor

-- Step 1: Get user_id and pathway_id
DO $$
DECLARE
  v_user_id UUID;
  v_pathway_id UUID;
  v_admin_id UUID;
BEGIN
  -- Get user_id
  SELECT user_id INTO v_user_id
  FROM profiles
  WHERE email = 'naik.abhira@gmail.com';
  
  -- Get pathway_id for Communication
  SELECT id INTO v_pathway_id
  FROM pathways
  WHERE name = 'Communication';
  
  -- Get admin user_id
  SELECT user_id INTO v_admin_id
  FROM profiles
  WHERE role = 'admin'
  LIMIT 1;
  
  -- Delete any existing pathway assignments for this user
  DELETE FROM user_progress WHERE user_id = v_user_id;
  DELETE FROM user_pathway WHERE user_id = v_user_id;
  
  -- Insert pathway assignment
  INSERT INTO user_pathway (
    user_id,
    pathway_id,
    pathway_name,
    is_current,
    assigned_by,
    assigned_at,
    enrolled_at
  ) VALUES (
    v_user_id,
    v_pathway_id,
    'Communication',
    true,
    v_admin_id,
    NOW(),
    NOW()
  );
  
  -- Insert initial progress
  INSERT INTO user_progress (
    user_id,
    pathway_id,
    current_level,
    current_score
  ) VALUES (
    v_user_id,
    v_pathway_id,
    1,
    0
  );
  
  RAISE NOTICE 'Pathway assigned successfully!';
END $$;

-- Verify the assignment
SELECT 
  'Assignment Verification' as check_type,
  up.pathway_name,
  up.is_current,
  up.assigned_at,
  prog.current_level,
  prog.current_score,
  p.email as user_email
FROM user_pathway up
JOIN profiles p ON p.user_id = up.user_id
LEFT JOIN user_progress prog ON prog.user_id = up.user_id AND prog.pathway_id = up.pathway_id
WHERE p.email = 'naik.abhira@gmail.com';
