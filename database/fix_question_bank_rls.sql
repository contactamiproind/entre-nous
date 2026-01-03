-- Fix RLS policies for question_bank table to allow admin access

-- Step 1: Enable RLS if not already enabled
ALTER TABLE question_bank ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if they exist (to recreate them)
DROP POLICY IF EXISTS "Admins can insert questions" ON question_bank;
DROP POLICY IF EXISTS "Admins can update questions" ON question_bank;
DROP POLICY IF EXISTS "Admins can delete questions" ON question_bank;
DROP POLICY IF EXISTS "Users can view questions" ON question_bank;

-- Step 3: Create policy for admin INSERT
CREATE POLICY "Admins can insert questions"
ON question_bank
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- Step 4: Create policy for admin UPDATE
CREATE POLICY "Admins can update questions"
ON question_bank
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- Step 5: Create policy for admin DELETE
CREATE POLICY "Admins can delete questions"
ON question_bank
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- Step 6: Create policy for users to SELECT/view questions
CREATE POLICY "Users can view questions"
ON question_bank
FOR SELECT
TO authenticated
USING (true);

-- Verify policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'question_bank';
