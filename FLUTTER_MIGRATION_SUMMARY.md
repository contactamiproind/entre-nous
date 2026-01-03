# Flutter Code Migration Summary

## ✅ Completed Updates

The Flutter project has been updated to work with the new database schema (`usr_dept` and `usr_progress` tables).

---

## **Files Updated**

### **1. Services**

#### **`lib/services/assignment_service.dart`** ✅
- Changed all queries from `user_pathway` → `usr_dept`
- Added new `assignPathwayWithQuestions()` method that calls the database RPC function
- Updated field names: `pathway_id` → `dept_id`, `pathway_name` → `dept_name`
- Updated status handling to include 'active', 'completed', 'paused'

**Key Changes:**
```dart
// NEW: Assign pathway with questions
Future<String> assignPathwayWithQuestions({
  required String userId,
  required String deptId,
  String? assignedBy,
}) async {
  final result = await _supabase.rpc(
    'assign_pathway_with_questions',
    params: {
      'p_user_id': userId,
      'p_dept_id': deptId,
      'p_assigned_by': assignedBy ?? _supabase.auth.currentUser?.id,
    },
  );
  return result as String; // Returns usr_dept_id
}
```

#### **`lib/services/user_service.dart`** ✅
- Updated `assignPathway()` to call RPC function instead of direct insert
- Changed `removePathwayAssignment()` to use `usr_dept` table
- Updated `getUserPathways()` to query `usr_dept`

---

### **2. Screens**

#### **`lib/screens/user_profile_detail_screen.dart`** ✅
- Updated `_assignPathway()` to use RPC function
- Changed pathway assignment queries from `user_pathway` → `usr_dept`
- Updated delete operations to use `dept_id` instead of `pathway_id`

**Key Change:**
```dart
// Assign pathway with questions using database function
await Supabase.instance.client.rpc(
  'assign_pathway_with_questions',
  params: {
    'p_user_id': widget.userId,
    'p_dept_id': pathwayId,
    'p_assigned_by': admin.id,
  },
);
```

#### **`lib/screens/my_departments_screen.dart`** ✅
- Updated to query `usr_dept` instead of `user_pathway`
- Changed field references to `dept_id`

#### **`lib/screens/user_management_screen.dart`** ✅
- Updated user deletion to delete from `usr_dept` instead of `user_pathway`

#### **`lib/screens/enhanced_admin_dashboard.dart`** ✅
- Updated enrolled users count query to use `usr_dept`

#### **`lib/screens/pathway_selection_screen.dart`** ✅
- Updated to query `usr_dept` with `dept_id` and `dept_name` fields
- Changed enrollment to use RPC function instead of direct insert

---

## **What Happens Now**

### **When Admin Assigns a Pathway:**

1. **Old Behavior (Broken):**
   ```dart
   // Only created pathway assignment
   await supabase.from('user_pathway').insert({...});
   // ❌ No questions assigned!
   ```

2. **New Behavior (Fixed):**
   ```dart
   // Calls database function
   await supabase.rpc('assign_pathway_with_questions', params: {...});
   
   // This automatically:
   // ✅ Creates usr_dept record
   // ✅ Finds all questions for the department
   // ✅ Creates usr_progress record for EACH question
   // ✅ Sets all questions to 'pending' status
   ```

### **Progress Tracking:**

- **`usr_dept`** table now shows:
  - `total_questions` - Total questions assigned
  - `answered_questions` - Questions answered
  - `correct_answers` - Correct answers count
  - `progress_percentage` - Auto-calculated percentage
  - `total_score` - Current score
  - `current_level` - Current difficulty level

- **`usr_progress`** table tracks each question:
  - `status` - pending/answered/skipped/flagged
  - `user_answer` - The answer submitted
  - `is_correct` - Whether answer was correct
  - `score_earned` - Points earned
  - `attempt_count` - Number of attempts

### **Automatic Updates:**

When a user answers a question, the trigger automatically updates `usr_dept` summary:
```dart
// Update usr_progress
await supabase.from('usr_progress').update({
  'status': 'answered',
  'user_answer': answer,
  'is_correct': isCorrect,
  'score_earned': points,
}).eq('id', progressId);

// Trigger automatically updates usr_dept:
// - Increments answered_questions
// - Updates total_score
// - Recalculates progress_percentage
// - Updates last_activity_at
```

---

## **Testing Checklist**

### **Admin Functions:**
- [ ] Assign pathway to user from admin dashboard
- [ ] Verify questions are assigned (check `usr_progress` table)
- [ ] View user's pathway assignments
- [ ] Delete pathway assignment
- [ ] View progress statistics

### **User Functions:**
- [ ] View assigned pathways
- [ ] Start quiz for assigned pathway
- [ ] Answer questions
- [ ] Verify progress updates automatically
- [ ] Switch between pathways
- [ ] View progress percentage

### **Database Verification:**
```sql
-- Check pathway assignment
SELECT * FROM usr_dept WHERE user_id = 'user-uuid';

-- Check assigned questions
SELECT 
    question_text,
    difficulty,
    status,
    points
FROM usr_progress
WHERE user_id = 'user-uuid'
AND dept_id = 'dept-uuid';

-- Check progress summary
SELECT 
    dept_name,
    total_questions,
    answered_questions,
    progress_percentage,
    total_score
FROM usr_dept
WHERE user_id = 'user-uuid';
```

---

## **Known Issues & Next Steps**

### **Files That May Need Updates:**

1. **`lib/services/progress_service.dart`** - May need updates to work with `usr_progress` table
2. **`lib/screens/quiz_screen.dart`** - May need to query `usr_progress` for questions
3. **`lib/screens/enhanced_user_dashboard.dart`** - May reference old table names
4. **Models** - May need field name updates (`pathway_id` → `dept_id`)

### **Recommended Next Steps:**

1. **Test the assignment flow:**
   ```bash
   # Run the app
   flutter run
   
   # As admin:
   # 1. Go to user profile
   # 2. Assign a pathway
   # 3. Check if questions appear
   ```

2. **Check for errors:**
   - Watch Flutter console for SQL errors
   - Check Supabase logs for RPC function calls
   - Verify data in database tables

3. **Update remaining files:**
   - Search for remaining `user_pathway` references
   - Update to `usr_dept`
   - Update field names as needed

---

## **Quick Reference: Field Name Changes**

| Old Field | New Field | Table |
|-----------|-----------|-------|
| `user_pathway` | `usr_dept` | Table name |
| `pathway_id` | `dept_id` | Foreign key |
| `pathway_name` | `dept_name` | Department name |
| `user_progress` | `usr_progress` | Table name (redesigned) |

---

## **Database Functions Available**

### **1. Assign Pathway with Questions**
```dart
final usrDeptId = await supabase.rpc(
  'assign_pathway_with_questions',
  params: {
    'p_user_id': userId,
    'p_dept_id': deptId,
    'p_assigned_by': adminId, // optional
  },
);
```

### **2. Get User Progress**
```sql
SELECT * FROM get_user_dept_progress(
  'user-uuid'::UUID,
  'dept-uuid'::UUID
);
```

### **3. Get Level Questions**
```sql
SELECT * FROM get_user_level_questions(
  'user-uuid'::UUID,
  'dept-uuid'::UUID,
  1  -- level number (optional)
);
```

---

## **Support**

If you encounter issues:

1. **Check Supabase logs** for RPC function errors
2. **Verify migration ran successfully** - check if `usr_dept` and `usr_progress` tables exist
3. **Check for old table references** - search codebase for `user_pathway`
4. **Test with a single user** before rolling out to all users

---

## **Rollback Plan**

If needed, you can rollback by:

1. Dropping new tables:
   ```sql
   DROP TABLE IF EXISTS usr_progress CASCADE;
   DROP TABLE IF EXISTS usr_dept CASCADE;
   ```

2. Reverting Flutter code changes (use git)

3. Continuing to use old `user_pathway` table

---

**Migration completed on:** January 3, 2026
**Database schema version:** 2.0 (usr_dept + usr_progress)
