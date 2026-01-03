-- ============================================
-- MIGRATION: Rename Pathway → Department
-- ============================================
-- This script renames all pathway-related tables and columns to department
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. RENAME TABLES
-- ============================================

-- Rename pathways table to departments
ALTER TABLE pathways RENAME TO departments;

-- Rename pathway_levels table to department_levels
ALTER TABLE pathway_levels RENAME TO department_levels;

-- Rename pathway_assignments table to department_assignments (if exists)
ALTER TABLE IF EXISTS pathway_assignments RENAME TO department_assignments;

-- ============================================
-- 2. RENAME COLUMNS IN department_levels
-- ============================================

ALTER TABLE department_levels 
RENAME COLUMN pathway_id TO department_id;

-- ============================================
-- 3. RENAME COLUMNS IN user_progress
-- ============================================

ALTER TABLE user_progress 
RENAME COLUMN pathway_id TO department_id;

-- ============================================
-- 4. RENAME COLUMNS IN department_assignments (if exists)
-- ============================================

ALTER TABLE IF EXISTS department_assignments 
RENAME COLUMN pathway_id TO department_id;

-- ============================================
-- 5. UPDATE FOREIGN KEY CONSTRAINTS
-- ============================================
-- Note: PostgreSQL automatically updates FK constraint names
-- but we'll verify they still work

-- ============================================
-- 6. VERIFICATION QUERIES
-- ============================================

-- Check departments table
SELECT 'Departments table:' as info, COUNT(*) as count FROM departments;

-- Check department_levels table
SELECT 'Department levels:' as info, COUNT(*) as count FROM department_levels;

-- Check user_progress references
SELECT 'User progress records:' as info, COUNT(*) as count FROM user_progress;

-- Show sample data
SELECT id, name, description FROM departments LIMIT 5;

SELECT id, department_id, level_number, level_name 
FROM department_levels 
ORDER BY department_id, level_number 
LIMIT 10;

-- ============================================
-- ROLLBACK (if needed)
-- ============================================
-- Uncomment these lines to rollback the changes:

-- ALTER TABLE departments RENAME TO pathways;
-- ALTER TABLE department_levels RENAME TO pathway_levels;
-- ALTER TABLE IF EXISTS department_assignments RENAME TO pathway_assignments;
-- ALTER TABLE department_levels RENAME COLUMN department_id TO pathway_id;
-- ALTER TABLE user_progress RENAME COLUMN department_id TO pathway_id;
-- ALTER TABLE IF EXISTS department_assignments RENAME COLUMN department_id TO pathway_id;
