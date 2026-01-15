-- ============================================
-- Add Process and SOP Departments
-- ============================================
-- This script creates Process and SOP departments
-- to match the three main categories

-- Check existing departments
SELECT id, title, category, subcategory, description
FROM departments
WHERE category IN ('Orientation', 'Process', 'SOP')
ORDER BY category;

-- Insert Process department if it doesn't exist
INSERT INTO departments (title, category, subcategory, description, created_at, updated_at)
SELECT 
  'Process',
  'Process',
  NULL,
  'Standard workflows and procedures',
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM departments WHERE title = 'Process' AND category = 'Process'
);

-- Insert SOP department if it doesn't exist
INSERT INTO departments (title, category, subcategory, description, created_at, updated_at)
SELECT 
  'SOP',
  'SOP',
  NULL,
  'Standard Operating Procedures',
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM departments WHERE title = 'SOP' AND category = 'SOP'
);

-- Verify all three departments exist
SELECT 
  id,
  title,
  category,
  subcategory,
  description,
  created_at
FROM departments
WHERE category IN ('Orientation', 'Process', 'SOP')
ORDER BY 
  CASE category
    WHEN 'Orientation' THEN 1
    WHEN 'Process' THEN 2
    WHEN 'SOP' THEN 3
  END;

-- Count questions per department
SELECT 
  d.title as department,
  d.category,
  COUNT(q.id) as question_count
FROM departments d
LEFT JOIN questions q ON q.dept_id = d.id
WHERE d.category IN ('Orientation', 'Process', 'SOP')
GROUP BY d.id, d.title, d.category
ORDER BY 
  CASE d.category
    WHEN 'Orientation' THEN 1
    WHEN 'Process' THEN 2
    WHEN 'SOP' THEN 3
  END;
