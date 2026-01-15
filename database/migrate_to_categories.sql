-- ============================================
-- Migration: Convert to Category-Based System
-- ============================================
-- This script migrates from department/level system to 3 main categories:
-- 1. Orientation (with subcategories: Values, Goals, Vision, Greetings)
-- 2. Process (no subcategories)
-- 3. SOP (no subcategories)
-- ============================================

-- Step 1: Create user_category_progress table
-- ============================================

CREATE TABLE IF NOT EXISTS user_category_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN ('Orientation', 'Process', 'SOP')),
    subcategory TEXT, -- Only for Orientation: 'Values', 'Goals', 'Vision', 'Greetings'
    
    -- Status tracking
    status TEXT DEFAULT 'locked' CHECK (status IN ('locked', 'in_progress', 'completed')),
    
    -- Progress metrics
    total_questions INTEGER DEFAULT 0,
    answered_questions INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    total_score INTEGER DEFAULT 0,
    max_possible_score INTEGER DEFAULT 0,
    progress_percentage NUMERIC(5,2) DEFAULT 0.00,
    
    -- Timestamps
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    last_activity_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id, category, subcategory)
);

COMMENT ON TABLE user_category_progress IS 'Tracks user progress through Orientation, Process, and SOP categories';

-- Indexes
CREATE INDEX idx_user_category_progress_user_id ON user_category_progress(user_id);
CREATE INDEX idx_user_category_progress_category ON user_category_progress(category);
CREATE INDEX idx_user_category_progress_status ON user_category_progress(status);
CREATE INDEX idx_user_category_progress_user_category ON user_category_progress(user_id, category);

-- Step 2: Update questions table to use new category structure
-- ============================================

-- Add category and subcategory columns if they don't exist
ALTER TABLE questions 
ADD COLUMN IF NOT EXISTS main_category TEXT CHECK (main_category IN ('Orientation', 'Process', 'SOP'));

-- Update existing questions.category to main_category for clarity
-- Note: We'll keep the old 'category' field for now and add 'main_category'

-- Step 3: Initialize user progress for all existing users
-- ============================================

-- For each user, create progress records for:
-- - Orientation subcategories (Values, Goals, Vision, Greetings) - unlocked
-- - Process - locked
-- - SOP - locked

INSERT INTO user_category_progress (user_id, category, subcategory, status)
SELECT 
    id as user_id,
    'Orientation' as category,
    subcategory,
    'in_progress' as status
FROM auth.users
CROSS JOIN (
    VALUES ('Values'), ('Goals'), ('Vision'), ('Greetings')
) AS subs(subcategory)
ON CONFLICT (user_id, category, subcategory) DO NOTHING;

-- Create Process category progress (locked)
INSERT INTO user_category_progress (user_id, category, subcategory, status)
SELECT 
    id as user_id,
    'Process' as category,
    NULL as subcategory,
    'locked' as status
FROM auth.users
ON CONFLICT (user_id, category, subcategory) DO NOTHING;

-- Create SOP category progress (locked)
INSERT INTO user_category_progress (user_id, category, subcategory, status)
SELECT 
    id as user_id,
    'SOP' as category,
    NULL as subcategory,
    'locked' as status
FROM auth.users
ON CONFLICT (user_id, category, subcategory) DO NOTHING;

-- Step 4: Migrate existing questions to new category structure
-- ============================================

-- Map questions to Orientation subcategories based on keywords
UPDATE questions 
SET main_category = 'Orientation',
    subcategory = 'Values'
WHERE (title ILIKE '%value%' OR description ILIKE '%value%' OR 'values' = ANY(tags))
  AND main_category IS NULL;

UPDATE questions 
SET main_category = 'Orientation',
    subcategory = 'Goals'
WHERE (title ILIKE '%goal%' OR description ILIKE '%goal%' OR 'goals' = ANY(tags))
  AND main_category IS NULL;

UPDATE questions 
SET main_category = 'Orientation',
    subcategory = 'Vision'
WHERE (title ILIKE '%vision%' OR description ILIKE '%vision%' OR 'vision' = ANY(tags))
  AND main_category IS NULL;

UPDATE questions 
SET main_category = 'Orientation',
    subcategory = 'Greetings'
WHERE (title ILIKE '%greet%' OR description ILIKE '%greet%' OR 'greetings' = ANY(tags))
  AND main_category IS NULL;

-- Map remaining questions to Process or SOP based on keywords
UPDATE questions 
SET main_category = 'Process',
    subcategory = NULL
WHERE (title ILIKE '%process%' OR description ILIKE '%process%' OR 'process' = ANY(tags))
  AND main_category IS NULL;

UPDATE questions 
SET main_category = 'SOP',
    subcategory = NULL
WHERE (title ILIKE '%sop%' OR title ILIKE '%standard operating%' OR 'sop' = ANY(tags))
  AND main_category IS NULL;

-- Default unmapped questions to Orientation - Values
UPDATE questions 
SET main_category = 'Orientation',
    subcategory = 'Values'
WHERE main_category IS NULL;

-- Step 5: Create function to update category progress
-- ============================================

CREATE OR REPLACE FUNCTION update_category_progress()
RETURNS TRIGGER AS $$
BEGIN
    -- Update progress for the specific category/subcategory
    UPDATE user_category_progress
    SET 
        total_questions = (
            SELECT COUNT(*) 
            FROM questions 
            WHERE main_category = NEW.category 
            AND (subcategory = NEW.subcategory OR (subcategory IS NULL AND NEW.subcategory IS NULL))
        ),
        answered_questions = (
            SELECT COUNT(DISTINCT question_id)
            FROM usr_progress
            WHERE user_id = NEW.user_id
            AND category = NEW.category
            AND (subcategory = NEW.subcategory OR (subcategory IS NULL AND NEW.subcategory IS NULL))
            AND is_answered = TRUE
        ),
        correct_answers = (
            SELECT COUNT(DISTINCT question_id)
            FROM usr_progress
            WHERE user_id = NEW.user_id
            AND category = NEW.category
            AND (subcategory = NEW.subcategory OR (subcategory IS NULL AND NEW.subcategory IS NULL))
            AND is_correct = TRUE
        ),
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE user_id = NEW.user_id
    AND category = NEW.category
    AND (subcategory = NEW.subcategory OR (subcategory IS NULL AND NEW.subcategory IS NULL));
    
    -- Calculate progress percentage
    UPDATE user_category_progress
    SET progress_percentage = CASE 
        WHEN total_questions > 0 THEN (answered_questions::NUMERIC / total_questions * 100)
        ELSE 0
    END
    WHERE user_id = NEW.user_id
    AND category = NEW.category
    AND (subcategory = NEW.subcategory OR (subcategory IS NULL AND NEW.subcategory IS NULL));
    
    -- Mark as completed if all questions answered
    UPDATE user_category_progress
    SET status = 'completed',
        completed_at = NOW()
    WHERE user_id = NEW.user_id
    AND category = NEW.category
    AND (subcategory = NEW.subcategory OR (subcategory IS NULL AND NEW.subcategory IS NULL))
    AND answered_questions >= total_questions
    AND total_questions > 0
    AND status != 'completed';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Create trigger for automatic progress updates
-- ============================================

DROP TRIGGER IF EXISTS trigger_update_category_progress ON usr_progress;

CREATE TRIGGER trigger_update_category_progress
AFTER INSERT OR UPDATE ON usr_progress
FOR EACH ROW
EXECUTE FUNCTION update_category_progress();

-- Step 7: Create function to unlock next category
-- ============================================

CREATE OR REPLACE FUNCTION unlock_next_category(p_user_id UUID, p_category TEXT)
RETURNS VOID AS $$
DECLARE
    v_next_category TEXT;
BEGIN
    -- Determine next category
    IF p_category = 'Orientation' THEN
        v_next_category := 'Process';
    ELSIF p_category = 'Process' THEN
        v_next_category := 'SOP';
    ELSE
        RETURN; -- SOP is the last category
    END IF;
    
    -- Check if all subcategories in current category are completed
    IF p_category = 'Orientation' THEN
        -- Check if all Orientation subcategories are completed
        IF (SELECT COUNT(*) FROM user_category_progress 
            WHERE user_id = p_user_id 
            AND category = 'Orientation' 
            AND status = 'completed') = 4 THEN
            
            -- Unlock next category
            UPDATE user_category_progress
            SET status = 'in_progress'
            WHERE user_id = p_user_id
            AND category = v_next_category
            AND status = 'locked';
        END IF;
    ELSE
        -- For Process and SOP (no subcategories)
        IF (SELECT status FROM user_category_progress 
            WHERE user_id = p_user_id 
            AND category = p_category) = 'completed' THEN
            
            -- Unlock next category
            UPDATE user_category_progress
            SET status = 'in_progress'
            WHERE user_id = p_user_id
            AND category = v_next_category
            AND status = 'locked';
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Step 8: Summary and verification queries
-- ============================================

-- Count users with category progress
SELECT 'Total users with category progress:' as info, COUNT(DISTINCT user_id) as count
FROM user_category_progress;

-- Count questions by category
SELECT 
    main_category,
    subcategory,
    COUNT(*) as question_count
FROM questions
WHERE main_category IS NOT NULL
GROUP BY main_category, subcategory
ORDER BY main_category, subcategory;

-- Show sample user progress
SELECT 
    u.email,
    ucp.category,
    ucp.subcategory,
    ucp.status,
    ucp.progress_percentage
FROM user_category_progress ucp
JOIN auth.users u ON u.id = ucp.user_id
LIMIT 10;

COMMENT ON FUNCTION update_category_progress() IS 'Automatically updates user progress when questions are answered';
COMMENT ON FUNCTION unlock_next_category(UUID, TEXT) IS 'Unlocks the next category when current category is completed';
