# Database Cleanup Guide

## Overview

After migrating to the new schema (`usr_dept` and `usr_progress`), the following tables/views are now **redundant** and can be safely dropped:

1. **`usr_stat`** table - Replaced by `usr_progress`
2. **`user_progress_summary`** view - Replaced by `usr_dept` (with auto-aggregation)

---

## Analysis: What Was Replaced

### **1. usr_stat Table**

**Old Purpose:**
- Tracked individual question answers
- Stored: `user_id`, `department_id`, `question_id`, `user_answer`, `is_correct`, `points_earned`
- Had `orientation_completed` flag

**Replaced By:** `usr_progress` table

**Why Better:**
- ✅ Tracks question **assignments** (not just answers)
- ✅ Status tracking: pending → answered → skipped
- ✅ Attempt count and time tracking
- ✅ Denormalized question metadata for performance
- ✅ Linked to `usr_dept` for automatic aggregation

---

### **2. user_progress_summary View**

**Old Purpose:**
- Aggregated view of user progress from `usr_stat`
- Used for dashboard statistics
- Showed: total questions, correct answers, scores

**Replaced By:** `usr_dept` table (with trigger)

**Why Better:**
- ✅ Real table (not view) - faster queries
- ✅ Auto-updated via trigger when `usr_progress` changes
- ✅ Includes: `total_questions`, `answered_questions`, `progress_percentage`, `total_score`
- ✅ No need for complex aggregation queries
- ✅ Includes status tracking (active/completed/paused)

---

## Code References to Update

### **Files Using `usr_stat`:**

#### **1. `lib/services/progress_service.dart`**
```dart
// OLD: Save to usr_stat
await _supabase.from('usr_stat').insert({...});

// NEW: Update usr_progress
await _supabase.from('usr_progress').update({
  'status': 'answered',
  'user_answer': answer,
  'is_correct': isCorrect,
  'score_earned': points,
}).eq('id', progressId);
```

#### **2. `lib/services/department_service.dart`**
```dart
// OLD: Check orientation from usr_stat
final response = await _supabase
  .from('usr_stat')
  .select('orientation_completed')
  .eq('user_id', userId);

// NEW: Check from usr_dept or use RPC function
final response = await _supabase.rpc('is_orientation_completed', 
  params: {'p_user_id': userId}
);
```

#### **3. `lib/services/user_service.dart`**
```dart
// OLD: Delete from usr_stat
await _supabase.from('usr_stat').delete().eq('user_id', userId);

// NEW: Delete from usr_progress (cascades from usr_dept)
await _supabase.from('usr_dept').delete().eq('user_id', userId);
// usr_progress will be deleted automatically via CASCADE
```

---

### **Files Using `user_progress_summary`:**

#### **1. `lib/services/progress_service.dart`**
```dart
// OLD: Query view
final response = await _supabase
  .from('user_progress_summary')
  .select()
  .eq('user_id', userId);

// NEW: Query usr_dept directly
final response = await _supabase
  .from('usr_dept')
  .select()
  .eq('user_id', userId);
```

#### **2. `lib/services/pathway_service.dart`**
```dart
// OLD: Check progress from view
final response = await _supabase
  .from('user_progress_summary')
  .select()
  .eq('user_id', userId)
  .eq('department_id', deptId);

// NEW: Use RPC function or query usr_dept
final response = await _supabase.rpc('get_user_dept_progress',
  params: {
    'p_user_id': userId,
    'p_dept_id': deptId,
  }
);
```

---

## Migration Steps

### **Step 1: Update Flutter Code**

Update all references to use new tables:

1. ✅ Replace `usr_stat` → `usr_progress`
2. ✅ Replace `user_progress_summary` → `usr_dept`
3. ✅ Update field names as needed
4. ✅ Test thoroughly

### **Step 2: Test the Application**

- [ ] Test pathway assignment
- [ ] Test question answering
- [ ] Test progress tracking
- [ ] Test orientation completion
- [ ] Test user deletion
- [ ] Test admin dashboard statistics

### **Step 3: Run Cleanup Script**

```bash
# Using Supabase SQL Editor
# Copy contents of cleanup_redundant_tables.sql and run

# Or using psql
psql -h db.xxxxx.supabase.co -U postgres -d postgres \
  -f database/cleanup_redundant_tables.sql
```

### **Step 4: Verify Cleanup**

```sql
-- Check that tables are dropped
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('usr_stat', 'user_progress_summary');
-- Should return 0 rows

-- Check new tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('usr_dept', 'usr_progress');
-- Should return 2 rows
```

---

## What the Cleanup Script Does

### **1. Drops Redundant Objects**
- Drops `user_progress_summary` view
- Drops `usr_stat` table (with CASCADE)
- Drops any dependent triggers/functions

### **2. Creates Compatibility View (Optional)**
Creates a new `user_progress_summary` view that maps to `usr_dept`:
```sql
CREATE VIEW user_progress_summary AS
SELECT 
    user_id,
    dept_id as department_id,
    answered_questions as total_questions_answered,
    correct_answers,
    total_score,
    progress_percentage
FROM usr_dept
WHERE status = 'active';
```

This allows old code to continue working temporarily.

### **3. Adds Helper Function**
Creates `is_orientation_completed(user_id)` function:
```sql
SELECT is_orientation_completed('user-uuid'::UUID);
-- Returns TRUE/FALSE based on usr_dept progress
```

---

## Rollback Plan

If you need to rollback:

### **Option 1: Restore from Backup**
```sql
-- If you created backups
CREATE TABLE usr_stat AS SELECT * FROM usr_stat_backup;
CREATE VIEW user_progress_summary AS SELECT * FROM user_progress_summary_backup;
```

### **Option 2: Recreate Tables**
You'll need to recreate the old schema and migrate data back from `usr_progress` and `usr_dept`.

---

## Benefits of Cleanup

### **Performance:**
- ✅ Fewer tables to query
- ✅ No complex view aggregations
- ✅ Faster dashboard queries

### **Maintainability:**
- ✅ Single source of truth for progress
- ✅ Automatic aggregation via triggers
- ✅ Cleaner schema

### **Storage:**
- ✅ Removes redundant data
- ✅ Reduces database size

---

## Comparison Table

| Feature | Old (usr_stat) | New (usr_progress) |
|---------|----------------|-------------------|
| Question assignment | ❌ No | ✅ Yes |
| Answer tracking | ✅ Yes | ✅ Yes |
| Status tracking | ❌ No | ✅ Yes (pending/answered/skipped) |
| Attempt count | ❌ No | ✅ Yes |
| Time tracking | ❌ No | ✅ Yes |
| Denormalized data | ❌ No | ✅ Yes (for performance) |
| Auto-aggregation | ❌ No | ✅ Yes (via trigger) |

| Feature | Old (user_progress_summary) | New (usr_dept) |
|---------|----------------------------|----------------|
| Type | View (slow) | Table (fast) |
| Real-time updates | ❌ No | ✅ Yes (trigger) |
| Status tracking | ❌ No | ✅ Yes |
| Level tracking | ❌ No | ✅ Yes |
| Completion tracking | ❌ Limited | ✅ Full |

---

## Testing Checklist

Before running cleanup:

- [ ] All Flutter code updated to use new tables
- [ ] Pathway assignment works
- [ ] Question answering updates progress
- [ ] Progress percentage calculates correctly
- [ ] Orientation completion tracking works
- [ ] User deletion cleans up properly
- [ ] Admin dashboard shows correct statistics
- [ ] No errors in Supabase logs
- [ ] No errors in Flutter console

After running cleanup:

- [ ] Application still works
- [ ] No SQL errors
- [ ] Progress tracking still works
- [ ] Statistics still display correctly

---

## Support

If you encounter issues:

1. **Check Supabase logs** for SQL errors
2. **Verify new tables have data** before dropping old ones
3. **Test with a single user** before full deployment
4. **Keep backups** until you're confident

---

## Summary

**Safe to Drop:**
- ✅ `usr_stat` table - Fully replaced by `usr_progress`
- ✅ `user_progress_summary` view - Fully replaced by `usr_dept`

**Action Required:**
1. Update Flutter code to use new tables
2. Test thoroughly
3. Run cleanup script
4. Verify everything works

**Result:**
- Cleaner database schema
- Better performance
- Automatic progress aggregation
- Single source of truth for user progress

---

**Last Updated:** January 3, 2026
