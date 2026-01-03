-- ============================================
-- Get Real Database Schema
-- ============================================
-- Run this in Supabase SQL Editor to get your actual schema
-- ============================================

-- Create a function to export schema (if it doesn't exist)
CREATE OR REPLACE FUNCTION export_table_schema(p_table_name TEXT)
RETURNS TABLE (
    column_name TEXT,
    data_type TEXT,
    is_nullable TEXT,
    column_default TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.column_name::TEXT,
        c.data_type::TEXT,
        c.is_nullable::TEXT,
        c.column_default::TEXT
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
    AND c.table_name = p_table_name
    ORDER BY c.ordinal_position;
END;
$$ LANGUAGE plpgsql;

-- Get schema for all your tables
SELECT 'questions' as table_name, * FROM export_table_schema('questions');
SELECT 'departments' as table_name, * FROM export_table_schema('departments');
SELECT 'profiles' as table_name, * FROM export_table_schema('profiles');
SELECT 'usr_dept' as table_name, * FROM export_table_schema('usr_dept');
SELECT 'usr_progress' as table_name, * FROM export_table_schema('usr_progress');
SELECT 'dept_levels' as table_name, * FROM export_table_schema('dept_levels');
SELECT 'usr_stat' as table_name, * FROM export_table_schema('usr_stat');
SELECT 'user_progress' as table_name, * FROM export_table_schema('user_progress');
SELECT 'quest_types' as table_name, * FROM export_table_schema('quest_types');

-- ============================================
-- Most Important: Check questions table structure
-- ============================================
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'questions'
ORDER BY ordinal_position;

-- Check if there are any questions
SELECT COUNT(*) as question_count FROM questions;

-- Sample a few questions to see structure
SELECT * FROM questions LIMIT 3;
