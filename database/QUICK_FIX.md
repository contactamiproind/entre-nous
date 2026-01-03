# Quick Fix for "column q.question_text does not exist" Error

## The Problem
The `assign_pathway_with_questions` function is using wrong column names.

## The Solution

### **Step 1: Go to Supabase Dashboard**
1. Open https://supabase.com/dashboard
2. Select your project
3. Go to **SQL Editor** (left sidebar)

### **Step 2: Run This SQL**

Copy and paste this ENTIRE script into SQL Editor and click **RUN**:

```sql
-- Drop old function
DROP FUNCTION IF EXISTS assign_pathway_with_questions(UUID, UUID, UUID);

-- Create fixed function
CREATE OR REPLACE FUNCTION assign_pathway_with_questions(
    p_user_id UUID,
    p_dept_id UUID,
    p_assigned_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_usr_dept_id UUID;
    v_dept_name TEXT;
    v_total_levels INTEGER;
    v_question_record RECORD;
BEGIN
    -- Get department name
    SELECT title INTO v_dept_name
    FROM departments
    WHERE id = p_dept_id;
    
    IF v_dept_name IS NULL THEN
        RAISE EXCEPTION 'Department not found: %', p_dept_id;
    END IF;
    
    -- Get total levels from JSONB
    SELECT jsonb_array_length(levels) INTO v_total_levels
    FROM departments
    WHERE id = p_dept_id;
    
    -- Create usr_dept record
    INSERT INTO usr_dept (
        user_id,
        dept_id,
        dept_name,
        assigned_by,
        total_levels,
        started_at
    ) VALUES (
        p_user_id,
        p_dept_id,
        v_dept_name,
        p_assigned_by,
        COALESCE(v_total_levels, 0),
        NOW()
    )
    RETURNING id INTO v_usr_dept_id;
    
    -- Assign all questions - FIXED COLUMN NAMES
    FOR v_question_record IN
        SELECT 
            q.id,
            COALESCE(q.title, 'Question') as question_text,
            COALESCE(q.description, '') as question_type,
            COALESCE(q.difficulty, 'Easy') as difficulty,
            q.category,
            q.subcategory,
            COALESCE(q.points, 1) as points,
            CASE 
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) = 'easy' THEN 1
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) IN ('mid', 'medium') THEN 2
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) = 'hard' THEN 3
                WHEN LOWER(COALESCE(q.difficulty, 'Easy')) = 'extreme' THEN 4
                ELSE 1
            END as level_number,
            COALESCE(q.difficulty, 'Easy') as level_name
        FROM questions q
        WHERE q.category = (SELECT category FROM departments WHERE id = p_dept_id)
        AND (
            q.subcategory = (SELECT subcategory FROM departments WHERE id = p_dept_id)
            OR (SELECT subcategory FROM departments WHERE id = p_dept_id) IS NULL
        )
    LOOP
        INSERT INTO usr_progress (
            user_id,
            dept_id,
            usr_dept_id,
            question_id,
            question_text,
            question_type,
            difficulty,
            category,
            subcategory,
            points,
            level_number,
            level_name,
            status
        ) VALUES (
            p_user_id,
            p_dept_id,
            v_usr_dept_id,
            v_question_record.id,
            v_question_record.question_text,
            v_question_record.question_type,
            v_question_record.difficulty,
            v_question_record.category,
            v_question_record.subcategory,
            v_question_record.points,
            v_question_record.level_number,
            v_question_record.level_name,
            'pending'
        );
    END LOOP;
    
    RETURN v_usr_dept_id;
END;
$$ LANGUAGE plpgsql;

-- Verify
SELECT 'Function updated successfully!' as status;
```

### **Step 3: Verify It Worked**

You should see: **"Function updated successfully!"**

### **Step 4: Test in Flutter App**

1. **Hot restart** your Flutter app (not just hot reload)
2. Go to user profile
3. Try assigning a department
4. Should work now!

---

## If Still Not Working

Run this to check if function exists:

```sql
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'assign_pathway_with_questions';
```

Should show 1 row with the function.
