-- Check current RLS policies on questions table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'questions';

-- If no policies exist or they're blocking reads, run this:
-- Enable RLS
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Enable read access for all users" ON questions;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON questions;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON questions;
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON questions;

-- Create new policies that allow admins full access
CREATE POLICY "Enable read access for all authenticated users"
ON questions FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Enable insert for admins"
ON questions FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

CREATE POLICY "Enable update for admins"
ON questions FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

CREATE POLICY "Enable delete for admins"
ON questions FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);
