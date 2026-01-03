# Production Deployment Guide

## Critical Issue: dept_name Not Saved

### Root Cause
The RPC function `assign_pathway_with_questions` is not saving `dept_name` to the `usr_dept` table, causing "Unknown Pathway" display.

---

## IMMEDIATE FIX (Run in Supabase SQL Editor)

### Step 1: Fix Existing Records
```sql
-- Update existing usr_dept records with NULL dept_name
UPDATE usr_dept
SET dept_name = d.title
FROM departments d
WHERE usr_dept.dept_id = d.id
AND usr_dept.dept_name IS NULL;
```

### Step 2: Run Complete Production Fix
Copy and run the entire `database/PRODUCTION_FIX.sql` file in Supabase SQL Editor.

This will:
- ✅ Fix existing NULL dept_name records
- ✅ Update RPC function to save dept_name correctly
- ✅ Add duplicate check
- ✅ Add proper error handling

---

## Home Screen Department Selection

The Home screen already has department selection in the "Pathway Tab". The issue is it's showing "Unknown Pathway" because `dept_name` is NULL.

After running the fix above:
1. Home screen will show correct department names
2. Users can click on departments to see levels
3. Users can click on levels to see questions

---

## Production Checklist

### Database
- [ ] Run `PRODUCTION_FIX.sql` in Supabase SQL Editor
- [ ] Verify `dept_name` is not NULL: `SELECT * FROM usr_dept;`
- [ ] Verify RPC function updated: Check function definition
- [ ] Delete old assignments: `DELETE FROM usr_dept WHERE dept_name IS NULL;`
- [ ] Reassign departments to users (will use new RPC function)

### Questions Setup
- [ ] Run `cleanup_questions_schema.sql` (removes redundant columns)
- [ ] Set `dept_id` on all questions:
  ```sql
  UPDATE questions 
  SET dept_id = 'your-dept-id-here'
  WHERE id IN ('question-id-1', 'question-id-2', ...);
  ```
- [ ] Verify questions linked: `SELECT id, title, dept_id FROM questions;`

### Flutter App
- [ ] Hot restart app (stop and start completely)
- [ ] Test user login
- [ ] Verify Home screen shows department names (not "Unknown Pathway")
- [ ] Test clicking department → see levels
- [ ] Test clicking level → see questions
- [ ] Test answering questions → progress updates

### Optional Cleanup
- [ ] Run `cleanup_redundant_tables.sql` (drops old `usr_stat` table)
- [ ] Remove unused code/comments
- [ ] Test with multiple users

---

## Complete User Flow (Production)

### Admin Flow:
1. Admin logs in
2. Goes to User Management
3. Selects user
4. Clicks "Assign Department"
5. Selects department (e.g., "Orientation - Vision")
6. System calls `assign_pathway_with_questions` RPC
7. Creates `usr_dept` record with **dept_name saved**
8. Creates `usr_progress` records for all questions with `dept_id`

### User Flow:
1. User logs in
2. **Home screen** shows assigned departments (from `usr_dept`)
3. User clicks on department card
4. Sees levels (from `departments.levels` JSONB)
5. Clicks on level
6. Sees assigned questions (from `usr_progress`)
7. Answers questions
8. Progress auto-updates in `usr_dept` (via trigger)

---

## Troubleshooting

### "Unknown Pathway" Still Showing
```sql
-- Check if dept_name is NULL
SELECT id, dept_name, dept_id FROM usr_dept;

-- If NULL, run the UPDATE query from Step 1 above
```

### No Questions Showing
```sql
-- Check if questions have dept_id set
SELECT id, title, dept_id FROM questions;

-- If NULL, set dept_id:
UPDATE questions SET dept_id = 'your-dept-id' WHERE id = 'question-id';
```

### Levels Not Showing
```sql
-- Check if department has levels in JSONB
SELECT id, title, levels FROM departments WHERE id = 'your-dept-id';

-- Levels should be a JSON array like:
-- [{"name": "Easy", "description": "..."}, {"name": "Mid", "description": "..."}]
```

---

## Files Modified for Production

### Database Scripts:
- `database/PRODUCTION_FIX.sql` - **RUN THIS FIRST**
- `database/migration_new_schema.sql` - Original migration
- `database/cleanup_questions_schema.sql` - Remove redundant columns
- `database/cleanup_redundant_tables.sql` - Drop old tables

### Flutter Files Updated:
- `lib/screens/my_departments_screen.dart` - Shows enrolled departments
- `lib/screens/enhanced_user_dashboard.dart` - Home screen with department cards
- `lib/screens/pathway_detail_screen.dart` - Shows levels from JSONB
- `lib/screens/quiz_screen.dart` - Loads questions from usr_progress
- `lib/services/progress_service.dart` - Queries usr_dept
- `lib/services/pathway_service.dart` - Queries usr_dept
- `lib/widgets/assign_pathways_tab.dart` - Uses RPC function

---

## Summary

**The main issue:** RPC function wasn't saving `dept_name` to `usr_dept` table.

**The fix:** Run `PRODUCTION_FIX.sql` which:
1. Updates existing records
2. Fixes RPC function to save dept_name
3. Adds duplicate check and error handling

**After fix:** Home screen will show correct department names and complete flow will work.

---

## Support

If issues persist after running the fix:
1. Check Supabase logs for errors
2. Verify RPC function definition
3. Check usr_dept table has dept_name populated
4. Ensure questions have dept_id set
5. Hot restart Flutter app completely

**Last Updated:** January 3, 2026
