-- Create Admin User
-- This script creates an admin account for the ENEPL App

-- Admin Credentials:
-- Email: admin@enepl.com
-- Password: Admin@123

-- Note: You need to create this user in Supabase Auth Dashboard first
-- Then run this script to set the role to admin

-- Step 1: Create the admin user in Supabase Auth Dashboard
-- Go to: Authentication > Users > Add User
-- Email: admin@enepl.com
-- Password: Admin@123
-- Auto Confirm User: YES

-- Step 2: After creating the user, get the user_id from auth.users
-- Then run this script to create the profile with admin role

-- Insert admin profile
-- Replace <USER_ID> with the actual UUID from auth.users
INSERT INTO profiles (user_id, email, role)
VALUES (
  '<USER_ID>',  -- Replace with actual user_id from auth.users
  'admin@enepl.com',
  'admin'
)
ON CONFLICT (user_id) 
DO UPDATE SET role = 'admin';

-- Verify admin user
SELECT p.*, u.email 
FROM profiles p
JOIN auth.users u ON p.user_id = u.id
WHERE p.role = 'admin';
