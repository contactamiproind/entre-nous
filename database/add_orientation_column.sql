-- Add orientation_completed column to user_progress table if it doesn't exist
-- Run this in Supabase SQL Editor

ALTER TABLE user_progress 
ADD COLUMN IF NOT EXISTS orientation_completed BOOLEAN DEFAULT FALSE;

-- Verify the column was added
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'user_progress' 
AND column_name = 'orientation_completed';
