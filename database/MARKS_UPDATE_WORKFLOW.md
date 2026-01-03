# Assignment Marks Update Workflow

## 📋 How Marks Get Updated

### **Initial State (When Assignment is Created)**
```sql
{
  assignment_name: "Orientation Program",
  marks: 0,              ← Starts at 0
  max_marks: 100,
  completed_at: NULL     ← Not completed yet
}
```

---

## 🔄 Update Workflow

### **Step 1: User Completes Assignment**
User finishes the orientation or level assignment in the app.

### **Step 2: Admin Reviews and Updates Marks**

**Option A: Using Admin Dashboard (Flutter)**
```dart
// Admin clicks "Edit Marks" button
await assignmentService.updateAssignment(
  assignmentId: assignment.id,
  marks: 95,  // Admin enters marks
);
```

**Option B: Using SQL (Supabase)**
```sql
-- Admin updates marks and marks as complete
UPDATE user_assignments 
SET 
  marks = 95,                    ← Update marks
  completed_at = NOW()           ← Mark as completed
WHERE id = 'assignment-id';
```

### **Step 3: Trigger Auto-Updates user_progress**
The database trigger automatically updates:
```sql
user_progress {
  total_marks: 95,               ← Sum of all marks
  completed_assignments: 1,      ← Count increases
  orientation_completed: TRUE    ← If orientation
}
```

---

## 💡 Example Scenarios

### **Scenario 1: Orientation Assignment**

**Initial:**
```sql
INSERT INTO user_assignments (user_id, assignment_name, orientation_completed, marks)
VALUES ('user-123', 'Orientation Program', TRUE, 0);
-- marks = 0, completed_at = NULL
```

**User completes → Admin updates:**
```sql
UPDATE user_assignments 
SET marks = 95, completed_at = NOW()
WHERE user_id = 'user-123' AND orientation_completed = TRUE;
-- marks = 95, completed_at = '2025-12-18 10:30:00'
```

**Result:**
- ✅ User gets 95 marks
- ✅ `user_progress.orientation_completed` = TRUE (via trigger)
- ✅ User can now select pathway

---

### **Scenario 2: Level Assignment**

**Admin creates assignment:**
```sql
INSERT INTO user_assignments (
  user_id, 
  assignment_name, 
  pathway_level_id,
  marks
) VALUES (
  'user-123',
  'Communication Level 1',
  'comm-level-1-id',
  0  ← Starts at 0
);
```

**User completes → Admin updates:**
```sql
UPDATE user_assignments 
SET marks = 85, completed_at = NOW()
WHERE id = 'assignment-id';
```

**Result:**
- ✅ User gets 85 marks for Level 1
- ✅ `user_progress.total_marks` increases by 85
- ✅ `user_progress.current_score` increases by 85
- ✅ May unlock next level if score requirement met

---

## 🎯 Admin Dashboard Actions

### **Mark Assignment Complete**
```dart
// In enhanced_admin_dashboard.dart
Future<void> _markComplete(UserAssignment assignment) async {
  // Show dialog to enter marks
  final marks = await _showMarksDialog();
  
  // Update assignment
  await _assignmentService.markAsCompleted(
    assignment.id, 
    marks  // Admin-entered marks
  );
  
  // Refresh data
  _loadData();
}
```

### **Edit Marks**
```dart
Future<void> _editAssignment(UserAssignment assignment) async {
  // Show dialog with current marks
  final newMarks = await _showEditDialog(assignment.marks);
  
  // Update marks
  await _assignmentService.updateAssignment(
    assignmentId: assignment.id,
    marks: newMarks,
  );
}
```

---

## 📊 Database Trigger (Auto-Update)

When marks are updated, this trigger runs automatically:

```sql
CREATE TRIGGER trigger_update_user_progress
AFTER INSERT OR UPDATE OR DELETE ON user_assignments
FOR EACH ROW
EXECUTE FUNCTION update_user_progress_from_assignments();
```

**What it does:**
1. Calculates total marks across all assignments
2. Counts completed assignments
3. Checks if orientation is complete
4. Updates `user_progress` table

---

## ✅ Summary

**Workflow:**
1. Assignment created with `marks = 0`
2. User completes assignment
3. Admin updates `marks` to actual score
4. Admin sets `completed_at = NOW()`
5. Trigger auto-updates `user_progress`

**Key Points:**
- ✅ Marks start at 0
- ✅ Admin updates marks when user completes
- ✅ `completed_at` timestamp marks completion
- ✅ Trigger automatically updates progress
- ✅ No manual calculation needed

Perfect for tracking user progress! 🎯
