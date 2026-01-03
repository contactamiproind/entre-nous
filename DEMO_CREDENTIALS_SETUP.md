# Demo Credentials Setup Guide

## Overview
This guide will help you set up demo credentials in your Supabase database and test the new sign-up functionality.

## ✅ What's Been Added

### 1. **Sign-Up Screen** (`lib/screens/signup_screen.dart`)
- New user registration form
- Fields: Full Name, Email, Phone, Username, Password
- Form validation
- Automatic profile creation

### 2. **Updated Login Screen**
- Added "Don't have an account? Sign Up" button
- Links to the new signup screen

### 3. **Welcome Screen**
- Already exists and is set as the initial route
- Shows for 3 seconds before navigating to login

### 4. **Storage Service Updates**
- Added `createUser()` method for user registration
- Automatically creates both user and profile records

## 🔧 Setup Instructions

### Step 1: Add Demo Credentials to Supabase

1. **Open your Supabase project** at https://supabase.com
2. **Go to SQL Editor** (left sidebar)
3. **Create a new query**
4. **Copy and paste** the contents of `database/insert_demo_credentials.sql`
5. **Run the query** (click "Run" button)
6. **Verify** the output shows:
   - 4 users created
   - 4 profiles created

### Step 2: Verify Database Tables

Run this query in Supabase SQL Editor to check:

```sql
-- Check users and profiles
SELECT 
    u.username,
    u.is_admin,
    u.current_level,
    p.full_name,
    p.email
FROM users u
LEFT JOIN profiles p ON u.id = p.user_id
ORDER BY u.username;
```

You should see:
- **admin** / admin123 (Admin User)
- **john** / john123 (John Doe)
- **sarah** / sarah123 (Sarah Smith)
- **user** / user123 (Test User)

## 🧪 Testing

### Test 1: Demo Login
1. Run the app
2. Wait for welcome screen (3 seconds)
3. Login screen appears
4. Try demo credentials:
   - Username: `user`
   - Password: `user123`
5. Should navigate to User Dashboard

### Test 2: Admin Login
1. Login with:
   - Username: `admin`
   - Password: `admin123`
2. Should navigate to Admin Dashboard

### Test 3: New User Sign-Up
1. On login screen, click **"Don't have an account? Sign Up"**
2. Fill in the form:
   - Full Name: Your Name
   - Email: your@email.com
   - Phone: +1234567890 (optional)
   - Username: testuser
   - Password: test123
   - Confirm Password: test123
3. Click **"Sign Up"**
4. Should see success message
5. Should navigate back to login
6. Login with new credentials
7. Should navigate to User Dashboard

## 📁 File Structure

```
quiz_app/
├── lib/
│   ├── screens/
│   │   ├── welcome_screen.dart      ✅ Shows on app start
│   │   ├── login_screen.dart        ✅ Updated with sign-up button
│   │   ├── signup_screen.dart       ✨ NEW - User registration
│   │   ├── user_dashboard.dart
│   │   └── admin_dashboard.dart
│   ├── services/
│   │   └── storage_service.dart     ✅ Added createUser method
│   └── main.dart                    ✅ Added /signup route
└── database/
    ├── schema.sql
    ├── seed.sql
    └── insert_demo_credentials.sql  ✨ NEW - Demo data script
```

## 🎯 App Flow

```
App Start
    ↓
Welcome Screen (3 seconds)
    ↓
Login Screen
    ├─→ Login with existing account → Dashboard
    └─→ "Sign Up" button → Sign-Up Screen
            ↓
        Create Account
            ↓
        Back to Login Screen
            ↓
        Login with new account → Dashboard
```

## 🔍 Troubleshooting

### Issue: Demo credentials don't work
**Solution:** Run `database/insert_demo_credentials.sql` in Supabase SQL Editor

### Issue: Sign-up fails with "Username already exists"
**Solution:** Choose a different username or check if the user already exists in Supabase

### Issue: Profile not showing after signup
**Solution:** Check Supabase logs and ensure the `profiles` table has proper RLS policies

### Issue: Welcome screen doesn't show
**Solution:** Check that `main.dart` has `initialRoute: '/'` pointing to `WelcomeScreen`

## 📝 Demo Credentials Reference

| Username | Password  | Role  | Full Name    |
|----------|-----------|-------|--------------|
| user     | user123   | User  | Test User    |
| admin    | admin123  | Admin | Admin User   |
| john     | john123   | User  | John Doe     |
| sarah    | sarah123  | User  | Sarah Smith  |

## 🚀 Next Steps

1. ✅ Run the SQL script in Supabase
2. ✅ Test demo login
3. ✅ Test new user sign-up
4. ✅ Verify profiles are created correctly
5. Consider adding:
   - Password strength indicator
   - Email verification
   - Forgot password functionality
   - Profile picture upload
