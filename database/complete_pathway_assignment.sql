-- Complete pathway assignment in one script
-- Run this in Supabase SQL Editor

-- Get the IDs we need
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
  
  RAISE NOTICE 'User ID: %', v_user_id;
  
  -- Get pathway_id for Communication
  SELECT id INTO v_pathway_id
  FROM pathways
  WHERE name = 'Communication';
  
  RAISE NOTICE 'Pathway ID: %', v_pathway_id;
  
  -- Get admin user_id
  SELECT user_id INTO v_admin_id
  FROM profiles
  WHERE role = 'admin'
  LIMIT 1;
  
  RAISE NOTICE 'Admin ID: %', v_admin_id;
  
  -- Check if IDs are valid
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not found!';
  END IF;
  
  IF v_pathway_id IS NULL THEN
    RAISE EXCEPTION 'Pathway not found!';
  END IF;
  
  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Admin not found!';
  END IF;
  
  -- Delete existing records
  DELETE FROM user_progress WHERE user_id = v_user_id;
  DELETE FROM user_pathway WHERE user_id = v_user_id;
  
  RAISE NOTICE 'Deleted existing records';
  
  -- Insert user_pathway
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
  
  RAISE NOTICE 'Inserted user_pathway';
  
  -- Insert user_progress
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
  
  RAISE NOTICE 'Inserted user_progress';
  RAISE NOTICE 'SUCCESS! Pathway assigned!';
END $$;

-- Verify the assignment
SELECT 
  'user_pathway' as table_name,
  up.pathway_name,
  up.is_current,
  up.assigned_at,
  p.email
FROM user_pathway up
JOIN profiles p ON p.user_id = up.user_id
WHERE p.email = 'naik.abhira@gmail.com';

SELECT 
  'user_progress' as table_name,
  prog.current_level,
  prog.current_score,
  p.email
FROM user_progress prog
JOIN profiles p ON p.user_id = prog.user_id
WHERE p.email = 'naik.abhira@gmail.com';
