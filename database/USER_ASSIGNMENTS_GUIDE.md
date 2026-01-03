# User Assignments - Enhanced Structure

## 📋 Updated Schema

The `user_assignments` table now tracks:

### ✅ What It Stores

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| **orientation_completed** | BOOLEAN | Is this an orientation assignment? | TRUE/FALSE |
| **marks** | INTEGER | Marks obtained by user | 85 |
| **max_marks** | INTEGER | Maximum possible marks | 100 |
| **pathway_level_id** | UUID | Which pathway level (optional) | Level 1 ID |
| **completed_at** | TIMESTAMP | When completed | 2025-12-18 |

---

## 🎯 How It Works

### **Scenario 1: Orientation Assignment**
```sql
INSERT INTO user_assignments (
  user_id, 
  assignment_name, 
  orientation_completed,  -- ✅ TRUE for orientation
  marks,                  -- ✅ Marks from orientation
  max_marks,
  pathway_level_id        -- NULL (not linked to level)
) VALUES (
  'user-123',
  'Orientation Program',
  TRUE,                   -- This IS orientation
  95,                     -- User scored 95
  100,
  NULL                    -- Not linked to any level
);
```

### **Scenario 2: Pathway Level Assignment**
```sql
INSERT INTO user_assignments (
  user_id,
  assignment_name,
  orientation_completed,  -- ✅ FALSE (not orientation)
  marks,                  -- ✅ Marks from this level
  max_marks,
  pathway_level_id        -- ✅ Linked to specific level
) VALUES (
  'user-123',
  'Communication Level 1 - Public Speaking',
  FALSE,                  -- This is NOT orientation
  85,                     -- User scored 85 in this level
  100,
  'comm-level-1-id'       -- Linked to Communication Level 1
);
```

---

## 📊 Example Data Flow

### **User Journey:**

1. **User completes orientation:**
   ```sql
   orientation_completed = TRUE
   marks = 95
   pathway_level_id = NULL
   ```

2. **Admin marks it complete** → `user_progress.orientation_completed = TRUE`

3. **User selects "Communication" pathway**

4. **User completes Level 1 assignment:**
   ```sql
   orientation_completed = FALSE
   marks = 85
   pathway_level_id = 'communication-level-1-id'
   ```

5. **User completes Level 2 assignment:**
   ```sql
   orientation_completed = FALSE
   marks = 92
   pathway_level_id = 'communication-level-2-id'
   ```

---

## 🔍 Useful Queries

### **Get all assignments with level info:**
```sql
SELECT 
  ua.assignment_name,
  ua.marks,
  ua.max_marks,
  ua.orientation_completed,
  p.name as pathway_name,
  pl.level_name,
  pl.level_number
FROM user_assignments ua
LEFT JOIN pathway_levels pl ON ua.pathway_level_id = pl.id
LEFT JOIN pathways p ON pl.pathway_id = p.id
WHERE ua.user_id = 'user-id'
ORDER BY ua.created_at;
```

### **Get orientation status:**
```sql
SELECT 
  assignment_name,
  marks,
  max_marks,
  completed_at
FROM user_assignments
WHERE user_id = 'user-id' 
  AND orientation_completed = TRUE;
```

### **Get marks by pathway level:**
```sql
SELECT 
  p.name as pathway,
  pl.level_number,
  pl.level_name,
  ua.marks,
  ua.max_marks,
  (ua.marks::float / ua.max_marks * 100) as percentage
FROM user_assignments ua
JOIN pathway_levels pl ON ua.pathway_level_id = pl.id
JOIN pathways p ON pl.pathway_id = p.id
WHERE ua.user_id = 'user-id'
  AND ua.orientation_completed = FALSE
ORDER BY p.name, pl.level_number;
```

---

## ✅ Summary

**The `user_assignments` table now tracks:**

1. ✅ **Orientation status** (`orientation_completed`)
2. ✅ **Marks obtained** (`marks`)
3. ✅ **Maximum marks** (`max_marks`)
4. ✅ **Which level** (`pathway_level_id`) - NEW!
5. ✅ **Completion time** (`completed_at`)

**This allows you to:**
- Track orientation separately from level assignments
- Know exactly which level each assignment is for
- Calculate marks per level
- See user progress through specific pathway levels
- Generate reports by pathway and level

Perfect for your ENEPL App! 🎯
