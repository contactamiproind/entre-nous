-- ============================================
-- Drop Unused dept_cat Table
-- ============================================
-- This script drops the unused dept_cat table
-- ============================================

-- Drop unused dept_cat table if it exists
DROP TABLE IF EXISTS dept_cat CASCADE;

SELECT 'dept_cat table dropped successfully!' as status;
