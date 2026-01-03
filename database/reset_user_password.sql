-- ============================================
-- Reset User Password in Supabase
-- ============================================
-- This script helps you reset a user's password
-- ============================================

-- OPTION 1: Send Password Reset Email (RECOMMENDED)
-- ============================================
-- This is the safest way - user gets email to reset their own password
-- Run this in Supabase SQL Editor or use the Dashboard

-- Get user's email first
SELECT 
    id,
    email,
    created_at,
    last_sign_in_at
FROM auth.users
WHERE email = 'user@example.com';  -- Replace with actual email

-- Then in Supabase Dashboard:
-- 1. Go to Authentication → Users
-- 2. Find the user
-- 3. Click the three dots (...)
-- 4. Click "Send password recovery"

-- ============================================
-- OPTION 2: Update Password Directly (Admin Only)
-- ============================================
-- WARNING: This requires Supabase service_role key
-- Cannot be done through SQL Editor - must use Admin API

-- Using curl (replace with your values):
/*
curl -X PUT 'https://svqdtryvcbnltfaqjxbf.supabase.co/auth/v1/admin/users/{user_id}' \
  -H "apikey: YOUR_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "new_password_here"
  }'
*/

-- ============================================
-- OPTION 3: Reset via Supabase Dashboard (EASIEST)
-- ============================================
-- 1. Go to https://supabase.com/dashboard
-- 2. Select your project
-- 3. Go to Authentication → Users (left sidebar)
-- 4. Find the user by email
-- 5. Click the three dots (...) on the right
-- 6. Choose one of:
--    - "Send password recovery" (sends email)
--    - "Reset password" (set new password directly)

-- ============================================
-- OPTION 4: Programmatic Reset (Flutter App)
-- ============================================
-- Add this to your Flutter app for users to reset their own password:

/*
// In your Flutter app
Future<void> sendPasswordResetEmail(String email) async {
  try {
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'your-app://reset-password',
    );
    
    print('Password reset email sent to $email');
  } catch (e) {
    print('Error sending reset email: $e');
  }
}
*/

-- ============================================
-- Helper: Find User by Email
-- ============================================
SELECT 
    id as user_id,
    email,
    phone,
    created_at,
    last_sign_in_at,
    email_confirmed_at,
    phone_confirmed_at
FROM auth.users
WHERE email ILIKE '%@gmail.com%'  -- Search pattern
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- Helper: Check User's Profile
-- ============================================
SELECT 
    p.user_id,
    p.email,
    p.role,
    u.email as auth_email,
    u.last_sign_in_at
FROM profiles p
LEFT JOIN auth.users u ON p.user_id = u.id
WHERE p.email ILIKE '%amit%'  -- Search pattern
ORDER BY p.created_at DESC;

-- ============================================
-- Summary
-- ============================================
-- RECOMMENDED APPROACH:
-- 1. Use Supabase Dashboard → Authentication → Users
-- 2. Find user by email
-- 3. Click "Send password recovery"
-- 4. User receives email with reset link
-- 
-- This is secure and follows best practices!
