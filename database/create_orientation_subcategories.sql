-- Create 16 department rows for Orientation subcategories
-- Each row will have category='Orientation' and subcategory='Vision', 'Values', etc.

-- Insert 16 rows into departments table, one for each Orientation subcategory
INSERT INTO departments (title, category, subcategory, description, created_at, updated_at) VALUES
('Orientation - Vision', 'Orientation', 'Vision', 'Company vision and mission', NOW(), NOW()),
('Orientation - Values', 'Orientation', 'Values', 'Core company values', NOW(), NOW()),
('Orientation - Goals', 'Orientation', 'Goals', 'Company goals and objectives', NOW(), NOW()),
('Orientation - Brand Guidelines', 'Orientation', 'Brand Guidelines', 'Brand identity and guidelines', NOW(), NOW()),
('Orientation - Job Sheet', 'Orientation', 'Job Sheet', 'Job responsibilities and expectations', NOW(), NOW()),
('Orientation - Juice of the story', 'Orientation', 'Juice of the story', 'Company story and culture', NOW(), NOW()),
('Orientation - How do you prioritize?', 'Orientation', 'How do you prioritize?', 'Priority management guidelines', NOW(), NOW()),
('Orientation - Greetings', 'Orientation', 'Greetings', 'Professional greeting standards', NOW(), NOW()),
('Orientation - Dress Code', 'Orientation', 'Dress Code', 'Workplace dress code policy', NOW(), NOW()),
('Orientation - ATTENDANCE/LEAVES', 'Orientation', 'ATTENDANCE/LEAVES', 'Attendance and leave policies', NOW(), NOW()),
('Orientation - OFFICE DECORUM', 'Orientation', 'OFFICE DECORUM', 'Office behavior and etiquette', NOW(), NOW()),
('Orientation - Master Class', 'Orientation', 'Master Class', 'Training and development programs', NOW(), NOW()),
('Orientation - WORKING STYLE', 'Orientation', 'WORKING STYLE', 'Work methodology and approach', NOW(), NOW()),
('Orientation - Vendor Interaction Guidelines', 'Orientation', 'Vendor Interaction Guidelines', 'How to interact with vendors', NOW(), NOW()),
('Orientation - Communication & Response Protocol', 'Orientation', 'Communication & Response Protocol', 'Communication standards and protocols', NOW(), NOW()),
('Orientation - Email Etiquette', 'Orientation', 'Email Etiquette', 'Professional email communication', NOW(), NOW());

-- Verify the insert
SELECT id, title, category, subcategory, created_at
FROM departments
WHERE category = 'Orientation'
ORDER BY title;
