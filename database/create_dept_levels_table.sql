-- ============================================
-- Create dept_levels Table Migration
-- ============================================
-- This migration:
-- 1. Drops the unused dept_cat table
-- 2. Creates the dept_levels table for storing pathway levels
-- ============================================

-- Drop unused dept_cat table if it exists
DROP TABLE IF EXISTS dept_cat CASCADE;

-- ============================================
-- TABLE: dept_levels
-- ============================================
-- Stores level information for each department/pathway

CREATE TABLE IF NOT EXISTS dept_levels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dept_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    level_number INTEGER NOT NULL,
    level_name TEXT NOT NULL,
    required_score INTEGER DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique level numbers per department
    CONSTRAINT unique_dept_level UNIQUE (dept_id, level_number)
);

COMMENT ON TABLE dept_levels IS 'Level definitions for each department/pathway';

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_dept_levels_dept_id ON dept_levels(dept_id);
CREATE INDEX idx_dept_levels_level_number ON dept_levels(level_number);

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger to update updated_at on dept_levels
DROP TRIGGER IF EXISTS trigger_dept_levels_updated_at ON dept_levels;
CREATE TRIGGER trigger_dept_levels_updated_at
    BEFORE UPDATE ON dept_levels
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

ALTER TABLE dept_levels ENABLE ROW LEVEL SECURITY;

-- Anyone can view dept_levels
DROP POLICY IF EXISTS "Anyone can view dept_levels" ON dept_levels;
CREATE POLICY "Anyone can view dept_levels" ON dept_levels
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- Admins can manage dept_levels
DROP POLICY IF EXISTS "Admins can manage dept_levels" ON dept_levels;
CREATE POLICY "Admins can manage dept_levels" ON dept_levels
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

SELECT 'dept_levels table created successfully!' as status;
