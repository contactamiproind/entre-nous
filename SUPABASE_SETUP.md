# Supabase Setup Guide

## Step 1: Access Supabase Dashboard

1. Go to [https://svqdtryvcbnltfaqjxbf.supabase.co](https://svqdtryvcbnltfaqjxbf.supabase.co)
2. Login to your Supabase account

## Step 2: Create Database Tables

1. In the Supabase dashboard, click on **SQL Editor** in the left sidebar
2. Click **New Query**
3. Copy and paste the entire contents of `supabase_schema.sql` into the editor
4. Click **Run** to execute the SQL script

This will create:
- `users` table with default users (user/user123, admin/admin123)
- `quiz_progress` table for tracking quiz attempts
- Necessary indexes for performance
- Row Level Security (RLS) policies

## Step 3: Verify Tables Created

1. Click on **Table Editor** in the left sidebar
2. You should see two tables:
   - `users` - should have 2 rows (user and admin)
   - `quiz_progress` - should be empty initially

## Step 4: Test the App

Run the Flutter app:
```bash
cd C:\Users\naika\.gemini\antigravity\scratch\quiz_app
flutter run -d windows
```

## Step 5: Verify Integration

### Test User Login
1. Login as `user` / `user123`
2. Check the console for "Supabase connected successfully"
3. Verify user data loads from Supabase

### Test Quiz Progress
1. Complete a quiz level
2. Go to Supabase dashboard → Table Editor → `quiz_progress`
3. Verify a new row was added with your score

### Test Level Progression
1. Pass a quiz (get at least 60% correct)
2. Return to dashboard
3. Verify you're now on the next level
4. Go to Supabase dashboard → Table Editor → `users`
5. Verify `current_level` was updated

### Test Admin Panel
1. Logout and login as `admin` / `admin123`
2. View all users
3. Edit a user's level
4. Go to Supabase dashboard → Table Editor → `users`
5. Verify the change was saved

## Troubleshooting

### Connection Issues
- Check that your Supabase URL and anon key are correct in `lib/config/supabase_config.dart`
- Ensure you have internet connection
- Check the Flutter console for error messages

### RLS Policy Issues
If you get permission errors:
1. Go to **Authentication** → **Policies** in Supabase dashboard
2. Verify policies are enabled for both tables
3. You may need to temporarily disable RLS for testing:
   ```sql
   ALTER TABLE users DISABLE ROW LEVEL SECURITY;
   ALTER TABLE quiz_progress DISABLE ROW LEVEL SECURITY;
   ```

### Data Not Syncing
- Check the Flutter console for error messages
- Verify the SQL schema was executed successfully
- Try refreshing the dashboard to reload data from Supabase

## Next Steps

Once verified, you can:
- Add more quiz questions
- Implement real-time updates using Supabase subscriptions
- Add user registration functionality
- Implement password hashing for security
- Add quiz history view in user dashboard
