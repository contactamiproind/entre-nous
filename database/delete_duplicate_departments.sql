-- ============================================
-- Delete Duplicate Departments
-- ============================================
-- This script removes duplicate department entries
-- keeping only the oldest entry for each title+category combination
-- ============================================

-- First, let's see all departments with their IDs
SELECT id, title, category, subcategory, description, created_at 
FROM departments 
ORDER BY title, category, created_at;

-- ============================================
-- Delete duplicates, keeping the oldest record for each title+category
-- ============================================

-- Delete duplicate departments, keeping only the first (oldest) one
DELETE FROM departments
WHERE id NOT IN (
    SELECT DISTINCT ON (title, category) id
    FROM departments
    ORDER BY title, category, created_at ASC
);

-- ============================================
-- Verify the cleanup
-- ============================================

SELECT 
    title,
    category,
    subcategory,
    description,
    created_at
FROM departments 
ORDER BY 
    CASE 
        WHEN title = 'General' THEN 1
        ELSE 2
    END,
    category;

SELECT COUNT(*) as total_departments FROM departments;

SELECT 'Duplicate departments deleted successfully!' as status;

-- ============================================
-- Expected Result: Should have exactly 8 departments
-- ============================================
-- General Departments (title='General'):
--   Title: 'General', Category: 'Orientation'
--   Title: 'General', Category: 'Process'
--   Title: 'General', Category: 'SOP'
--
-- Specific Departments (title=category):
--   Title: 'Production', Category: 'Production'
--   Title: 'Communication', Category: 'Communication'
--   Title: 'Ideation', Category: 'Ideation'
--   Title: 'Client Servicing', Category: 'Client Servicing'
--   Title: 'Creative', Category: 'Creative'

