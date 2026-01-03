-- ============================================
-- MIGRATION: Add role column to profiles table
-- ============================================
-- Run this BEFORE running the full schema.sql if you have existing data

-- Create user role enum if it doesn't exist
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('user', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Add role column to profiles table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'role'
    ) THEN
        ALTER TABLE profiles ADD COLUMN role user_role DEFAULT 'user';
        
        -- Update existing admin users based on users.is_admin
        UPDATE profiles p
        SET role = 'admin'
        FROM users u
        WHERE p.user_id = u.id AND u.is_admin = TRUE;
        
        RAISE NOTICE 'Role column added successfully';
    ELSE
        RAISE NOTICE 'Role column already exists';
    END IF;
END $$;

-- Verify the change
SELECT 'Profiles with role column:' as info, COUNT(*) as count FROM profiles WHERE role IS NOT NULL;
