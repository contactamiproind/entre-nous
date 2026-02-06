-- ============================================
-- Restructure Departments
-- ============================================
-- This script restructures the departments table:
-- 1. Update Orientation, Process, SOP to have title='General' and category='Orientation'/'Process'/'SOP'
-- 2. Add new departments: Production, Communication, Ideation, Client Servicing, Creative
--    with title and category matching the department name
-- ============================================

-- First, let's see what we currently have
SELECT id, title, category, subcategory, description FROM departments ORDER BY title;

-- ============================================
-- Update existing departments to have title='General'
-- ============================================

-- Orientation: title='General', category='Orientation'
UPDATE departments 
SET 
    title = 'General',
    category = 'Orientation',
    subcategory = NULL,
    description = 'Core company values and culture'
WHERE LOWER(title) = 'orientation' OR category = 'Orientation';

-- Process: title='General', category='Process'
UPDATE departments 
SET 
    title = 'General',
    category = 'Process',
    subcategory = NULL,
    description = 'Standard workflows and procedures'
WHERE LOWER(title) = 'process' OR category = 'Process';

-- SOP: title='General', category='SOP'
UPDATE departments 
SET 
    title = 'General',
    category = 'SOP',
    subcategory = NULL,
    description = 'Standard Operating Procedures'
WHERE LOWER(title) = 'sop' OR category = 'SOP';

-- Production: title='General', category='Production'
UPDATE departments 
SET 
    title = 'General',
    category = 'Production',
    subcategory = NULL,
    description = 'Production related questions'
WHERE LOWER(title) = 'production' OR category = 'Production';

-- ============================================
-- Add new department-specific pathways
-- ============================================

-- Production Department
INSERT INTO departments (title, description, category, subcategory, levels)
VALUES (
    'Production',
    'Production department processes and workflows',
    'Production',
    NULL,
    '[]'::jsonb
)
ON CONFLICT DO NOTHING;

-- Communication Department
INSERT INTO departments (title, description, category, subcategory, levels)
VALUES (
    'Communication',
    'Communication department processes and workflows',
    'Communication',
    NULL,
    '[]'::jsonb
)
ON CONFLICT DO NOTHING;

-- Ideation Department
INSERT INTO departments (title, description, category, subcategory, levels)
VALUES (
    'Ideation',
    'Ideation department processes and workflows',
    'Ideation',
    NULL,
    '[]'::jsonb
)
ON CONFLICT DO NOTHING;

-- Client Servicing Department
INSERT INTO departments (title, description, category, subcategory, levels)
VALUES (
    'Client Servicing',
    'Client servicing department processes and workflows',
    'Client Servicing',
    NULL,
    '[]'::jsonb
)
ON CONFLICT DO NOTHING;

-- Creative Department
INSERT INTO departments (title, description, category, subcategory, levels)
VALUES (
    'Creative',
    'Creative department processes and workflows',
    'Creative',
    NULL,
    '[]'::jsonb
)
ON CONFLICT DO NOTHING;

-- ============================================
-- Verify the changes
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

SELECT 'Departments restructured successfully!' as status;

-- ============================================
-- Expected Result:
-- ============================================
-- Title: 'General', Category: 'Orientation'
-- Title: 'General', Category: 'Process'
-- Title: 'General', Category: 'SOP'
-- Title: 'Production', Category: 'Production'
-- Title: 'Communication', Category: 'Communication'
-- Title: 'Ideation', Category: 'Ideation'
-- Title: 'Client Servicing', Category: 'Client Servicing'
-- Title: 'Creative', Category: 'Creative'

