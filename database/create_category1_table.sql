-- Create category1 table for Orientation subcategories
-- This creates a separate table to store the 16 orientation topics

-- Create the category1 table
CREATE TABLE IF NOT EXISTS category1 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    display_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_category1_department ON category1(department_id);

-- Insert the 16 Orientation subcategories
-- First, get the Orientation department ID
DO $$
DECLARE
    orientation_dept_id UUID;
BEGIN
    -- Get the Orientation department ID
    SELECT id INTO orientation_dept_id 
    FROM departments 
    WHERE category = 'Orientation' OR title = 'Orientation'
    LIMIT 1;

    -- Insert all 16 subcategories
    INSERT INTO category1 (department_id, name, display_order) VALUES
    (orientation_dept_id, 'Vision', 1),
    (orientation_dept_id, 'Values', 2),
    (orientation_dept_id, 'Goals', 3),
    (orientation_dept_id, 'Brand Guidelines', 4),
    (orientation_dept_id, 'Job Sheet', 5),
    (orientation_dept_id, 'Juice of the story', 6),
    (orientation_dept_id, 'How do you prioritize?', 7),
    (orientation_dept_id, 'Greetings', 8),
    (orientation_dept_id, 'Dress Code', 9),
    (orientation_dept_id, 'ATTENDANCE/LEAVES', 10),
    (orientation_dept_id, 'OFFICE DECORUM', 11),
    (orientation_dept_id, 'Master Class', 12),
    (orientation_dept_id, 'WORKING STYLE', 13),
    (orientation_dept_id, 'Vendor Interaction Guidelines', 14),
    (orientation_dept_id, 'Communication & Response Protocol', 15),
    (orientation_dept_id, 'Email Etiquette', 16);
END $$;

-- Grant permissions
GRANT ALL ON category1 TO authenticated;

-- Verify the insert
SELECT c1.id, c1.name, c1.display_order, d.title as department_name
FROM category1 c1
JOIN departments d ON c1.department_id = d.id
ORDER BY c1.display_order;
