# Admin Dashboard - Pathway Assignment Guide

## ✅ Feature Already Implemented!

The pathway assignment feature is **fully functional** in your admin dashboard. Here's how to use it:

## How to Assign Pathways to Users

### Step 1: Login as Admin
1. Open the app
2. Select **"Admin"** role on login screen
3. Enter admin credentials

### Step 2: Access Pathway Assignment
1. You'll land on the **Admin Dashboard Home** tab
2. Look for **"Quick Actions"** section
3. Click the **"Assign Pathway"** button (blue button with person icon)

### Step 3: Assign Pathway
A dialog will appear with:
1. **Select User** dropdown - Choose the user email
2. **Select Pathway** dropdown - Choose from all 16 pathways
3. Click **"Assign Pathway"** button

### Step 4: Verify Assignment
The pathway will be immediately assigned to the user. The user will see it in their app:
- **Home screen**: Shows as "CURRENT PATHWAY" (if it's the first/current one)
- **Pathway tab**: Shows in the list of "My Enrolled Pathways"

## How It Works

When you assign a pathway via the admin dashboard:

1. **Database Update**: A new row is inserted into `user_pathway` table:
   ```sql
   INSERT INTO user_pathway (user_id, pathway_id, assigned_at, is_current, assigned_by)
   ```

2. **User App Updates**: The user's app automatically reflects the change:
   - Pathway appears in "Pathway" tab
   - User can click it to view levels
   - User can start quizzes (if questions exist)

3. **Multiple Pathways**: Users can have multiple pathways assigned:
   - Each assignment creates a new row in `user_pathway`
   - One pathway is marked as "current" (`is_current = true`)
   - All assigned pathways show in the Pathway tab

## Current Pathway Status

Based on your database:
- **Total Pathways**: 16
- **Pathways with Questions**:
  - Vision: 2 questions (Easy: 1, Mid: 1)
  - Values: 1 question (Easy: 1)
  - Orientation - Brand Guidelines: 1 question (Easy: 1)
- **Pathways without Questions**: 13 (will show "No questions available")

## Testing the Feature

1. **Login as admin**
2. **Click "Assign Pathway"** button
3. **Select** `abhira123@gmail.com` as user
4. **Select** "Vision" as pathway
5. **Click "Assign Pathway"**
6. **Logout** and login as `abhira123@gmail.com` (user role)
7. **Click "Pathway" tab** → You should see Vision pathway
8. **Click Vision** → You should see Easy and Mid levels
9. **Click Easy** → You should see 1 question

## Important Notes

✅ **Feature is working** - No code changes needed!

⚠️ **Only 4 questions total** - Most pathways will show "No questions available"

💡 **Next Steps**:
1. Add more questions to pathways via "Q-Bank" tab in admin dashboard
2. Link questions to pathway levels using `questions.level_id` field
3. Test with multiple pathway assignments per user

## Troubleshooting

**Issue**: User doesn't see assigned pathway
- **Solution**: Refresh the user app (hot reload or restart)

**Issue**: "No questions available for this level yet"
- **Solution**: The pathway/level has no questions. Add questions via admin dashboard Q-Bank tab

**Issue**: Pathway assignment fails
- **Solution**: Check Supabase logs for errors. Ensure `user_pathway` table exists and has correct permissions
