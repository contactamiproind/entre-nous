# Supabase Authentication Migration Guide

## ✅ What Changed

Your app now uses **Supabase Authentication** instead of a custom users table.

### Before:
- Users stored in `public.users` table
- Username + password authentication
- Manual password storage

### After:
- Users stored in `auth.users` table (Supabase Auth)
- Email + password authentication
- Secure password hashing by Supabase
- Email verification support

---

## 🔧 Setup Steps

### 1. Run Database Schema
```sql
-- In Supabase SQL Editor, run:
database/schema.sql
```

### 2. Create Admin User

**Option A: Via Supabase Dashboard (Recommended)**
1. Go to **Authentication → Users**
2. Click **"Add User"**
3. Enter:
   - Email: `admin@enepl.com`
   - Password: `admin123`
   - Auto Confirm User: ✅ Yes
4. Click **"Create User"**
5. Copy the User ID
6. Run this SQL:
   ```sql
   UPDATE profiles
   SET role = 'admin'
   WHERE user_id = 'PASTE_USER_ID_HERE';
   ```

**Option B: Via SQL Script**
```sql
-- Run database/create_admin_user.sql
-- Follow instructions in the file
```

### 3. Test the App

**Test Accounts:**
- **Admin:** `admin@enepl.com` / `admin123`
- **User:** Sign up with any email

---

## 📊 How It Works Now

### Signup Flow:
1. User enters email + password
2. Supabase creates user in `auth.users`
3. App creates profile in `profiles` table
4. App creates progress in `user_progress` table
5. User can login

### Login Flow:
1. User enters email + password
2. Supabase verifies credentials
3. App checks user role in `profiles`
4. Redirects to admin or user dashboard

---

## 🗄️ Database Structure

### auth.users (Supabase Managed)
- Stores authentication data
- Managed by Supabase
- Secure password hashing
- Email verification

### profiles (Your Table)
- Links to `auth.users` via `user_id`
- Stores user info (name, email, phone)
- Stores role (user/admin)

### user_progress (Your Table)
- Links to `auth.users` via `user_id`
- Tracks orientation and pathway progress

---

## ✅ Benefits

1. **Security:** Supabase handles password hashing
2. **Email Verification:** Built-in email confirmation
3. **Password Reset:** Forgot password functionality
4. **Session Management:** Automatic token refresh
5. **Best Practices:** Industry-standard authentication

---

## 🧪 Testing

### Test Signup:
1. Open app
2. Click "Sign Up"
3. Enter email, password, name
4. Click "Sign Up"
5. Login with same credentials

### Test Login:
1. Open app
2. Enter email + password
3. Click "Login"
4. Should redirect to dashboard

### Test Admin:
1. Create admin user (see Step 2 above)
2. Login with admin@enepl.com
3. Should see admin dashboard

---

## 📝 Files Updated

- ✅ `lib/screens/signup_screen.dart` - Uses Supabase Auth
- ✅ `lib/screens/login_screen.dart` - Uses Supabase Auth
- ✅ `database/create_admin_user.sql` - Admin setup script

---

## 🚀 Next Steps

1. Run schema.sql in Supabase
2. Create admin user
3. Test signup/login
4. Rebuild Android APK
5. Test on device

Your app now uses professional-grade authentication! 🎉
