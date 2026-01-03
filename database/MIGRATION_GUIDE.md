# Database Migration Guide: Fix Pathway Assignment Bug

## Problem Statement

When assigning a pathway to a user, only the pathway assignment is created in `user_pathway`, but the associated questions are **not** being assigned to the user. This means users cannot see or answer questions for their assigned pathways.

## Root Cause

The current implementation only creates a record in `user_pathway` but doesn't:
1. Create individual question assignments
2. Track question-level progress
3. Store user answers

## Solution

Redesign the database schema with two new tables:

### 1. **`usr_dept`** (replaces `user_pathway`)
- Stores the **overall department assignment summary**
- Tracks aggregated progress (total questions, answered, score, etc.)
- One record per user per department

### 2. **`usr_progress`** (new design)
- Stores **individual question assignments**
- Tracks each question's status (pending, answered, skipped)
- Stores user answers and scores
- Multiple records per department assignment (one per question)

## Migration Steps

### Step 1: Run the Migration SQL

```bash
# Using psql
psql -h db.xxxxx.supabase.co -U postgres -d postgres -f database/migration_new_schema.sql

# Or using Supabase SQL Editor
# Copy contents of migration_new_schema.sql and run in SQL Editor
```

### Step 2: Verify Tables Created

```sql
-- Check usr_dept table
SELECT * FROM usr_dept LIMIT 5;

-- Check usr_progress table
SELECT * FROM usr_progress LIMIT 5;

-- Check triggers
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE event_object_table IN ('usr_dept', 'usr_progress');
```

### Step 3: Test the Assignment Function

```sql
-- Assign a pathway to a user (this will also assign all questions)
SELECT assign_pathway_with_questions(
    'user-uuid-here'::UUID,
    'dept-uuid-here'::UUID,
    'admin-uuid-here'::UUID  -- optional
);

-- Check if questions were assigned
SELECT 
    ud.dept_name,
    ud.total_questions,
    ud.answered_questions,
    ud.progress_percentage
FROM usr_dept ud
WHERE ud.user_id = 'user-uuid-here'::UUID;

-- View assigned questions
SELECT 
    question_text,
    difficulty,
    status,
    points
FROM usr_progress
WHERE user_id = 'user-uuid-here'::UUID
AND dept_id = 'dept-uuid-here'::UUID;
```

## Schema Comparison

### Old Schema (user_pathway)
```sql
user_pathway
├── id
├── user_id
├── pathway_id
├── pathway_name
├── is_current
├── assigned_at
└── completed_at
```

**Problem:** No question tracking!

### New Schema (usr_dept + usr_progress)

**usr_dept** (Summary)
```sql
usr_dept
├── id
├── user_id
├── dept_id
├── dept_name
├── status (active/completed/paused)
├── total_questions ← Aggregated
├── answered_questions ← Aggregated
├── correct_answers ← Aggregated
├── total_score ← Aggregated
├── progress_percentage ← Aggregated
├── current_level
├── assigned_at
└── completed_at
```

**usr_progress** (Question-level)
```sql
usr_progress
├── id
├── user_id
├── dept_id
├── usr_dept_id (FK to usr_dept)
├── question_id (FK to questions)
├── question_text (denormalized)
├── question_type
├── difficulty
├── level_number
├── status (pending/answered/skipped)
├── user_answer ← Stores answer
├── is_correct ← Graded result
├── score_earned
├── attempt_count
└── time_spent_seconds
```

## How It Works

### 1. Assigning a Pathway

**Old Way (Broken):**
```dart
await supabase.from('user_pathway').insert({
  'user_id': userId,
  'pathway_id': pathwayId,
});
// Questions NOT assigned! ❌
```

**New Way (Fixed):**
```sql
-- Call the function
SELECT assign_pathway_with_questions(
    'user-uuid',
    'dept-uuid',
    'admin-uuid'
);

-- This automatically:
-- 1. Creates usr_dept record
-- 2. Finds all questions for this department
-- 3. Creates usr_progress record for EACH question
-- 4. Sets status to 'pending'
```

### 2. Automatic Progress Updates

When a user answers a question:
```dart
await supabase.from('usr_progress').update({
  'status': 'answered',
  'user_answer': answer,
  'is_correct': isCorrect,
  'score_earned': points,
}).eq('id', progressId);
```

**Trigger automatically updates usr_dept:**
- Increments `answered_questions`
- Updates `total_score`
- Recalculates `progress_percentage`
- Updates `last_activity_at`

### 3. Getting User's Questions

```sql
-- Get questions for current level
SELECT * FROM get_user_level_questions(
    'user-uuid'::UUID,
    'dept-uuid'::UUID,
    1  -- level number (optional)
);
```

## Flutter Code Changes Required

### 1. Update Assignment Service

**File:** `lib/services/assignment_service.dart`

```dart
// OLD: Direct insert
Future<void> assignPathway(String userId, String deptId) async {
  await _supabase.from('user_pathway').insert({...});
}

// NEW: Call database function
Future<String> assignPathway(String userId, String deptId) async {
  final result = await _supabase.rpc('assign_pathway_with_questions', 
    params: {
      'p_user_id': userId,
      'p_dept_id': deptId,
      'p_assigned_by': _supabase.auth.currentUser?.id,
    }
  );
  return result as String; // Returns usr_dept_id
}
```

### 2. Update Progress Service

**File:** `lib/services/progress_service.dart`

```dart
// Get user's assigned questions
Future<List<Question>> getUserQuestions(String userId, String deptId) async {
  final response = await _supabase
    .from('usr_progress')
    .select('*')
    .eq('user_id', userId)
    .eq('dept_id', deptId)
    .eq('status', 'pending')
    .order('level_number');
  
  return response.map((json) => Question.fromJson(json)).toList();
}

// Submit answer
Future<void> submitAnswer({
  required String progressId,
  required String answer,
  required bool isCorrect,
  required int points,
}) async {
  await _supabase.from('usr_progress').update({
    'status': 'answered',
    'user_answer': answer,
    'is_correct': isCorrect,
    'score_earned': isCorrect ? points : 0,
    'attempt_count': 1,
    'last_attempted_at': DateTime.now().toIso8601String(),
    'completed_at': DateTime.now().toIso8601String(),
  }).eq('id', progressId);
}
```

### 3. Update User Profile Screen

**File:** `lib/screens/user_profile_detail_screen.dart`

```dart
// OLD: Query user_pathway
final assignments = await _supabase
  .from('user_pathway')
  .select('*')
  .eq('user_id', userId);

// NEW: Query usr_dept with aggregated data
final assignments = await _supabase
  .from('usr_dept')
  .select('*')
  .eq('user_id', userId)
  .order('assigned_at', ascending: false);

// Now you have progress data!
// assignments[0]['total_questions']
// assignments[0]['answered_questions']
// assignments[0]['progress_percentage']
```

## Testing Checklist

- [ ] Run migration SQL successfully
- [ ] Verify tables created: `usr_dept`, `usr_progress`
- [ ] Test `assign_pathway_with_questions()` function
- [ ] Verify questions are assigned when pathway is assigned
- [ ] Test answering a question updates `usr_dept` summary
- [ ] Update Flutter code to use new tables
- [ ] Test assignment flow in UI
- [ ] Verify progress tracking works
- [ ] Test with multiple users and departments

## Rollback Plan

If you need to rollback:

```sql
-- Drop new tables
DROP TABLE IF EXISTS usr_progress CASCADE;
DROP TABLE IF EXISTS usr_dept CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS assign_pathway_with_questions CASCADE;
DROP FUNCTION IF EXISTS update_usr_dept_summary CASCADE;
DROP FUNCTION IF EXISTS get_user_dept_progress CASCADE;
DROP FUNCTION IF EXISTS get_user_level_questions CASCADE;

-- Keep using old user_pathway table
```

## Benefits of New Schema

✅ **Questions automatically assigned** when pathway is assigned  
✅ **Track individual question progress** (pending, answered, skipped)  
✅ **Store user answers** for review and analytics  
✅ **Automatic progress calculation** via triggers  
✅ **Better performance** with denormalized data  
✅ **Detailed analytics** (time spent, attempt count, etc.)  
✅ **Level-based progression** support  
✅ **Scalable** for future features (hints, explanations, etc.)  

## Next Steps

1. Run the migration SQL
2. Update Flutter services to use new tables
3. Test thoroughly with test users
4. Deploy to production
5. Monitor for any issues

## Support

If you encounter issues:
1. Check Supabase logs for errors
2. Verify foreign key relationships
3. Ensure questions exist for the department category/subcategory
4. Check trigger execution logs
