-- Fix RLS policy for user_pathway to allow admin assignment
-- Run this in Supabase SQL Editor

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own pathway enrollments" ON user_pathway;
DROP POLICY IF EXISTS "Users can enroll in pathways" ON user_pathway;
DROP POLICY IF EXISTS "Users can update their pathway progress" ON user_pathway;
DROP POLICY IF EXISTS "Admins can manage all pathway enrollments" ON user_pathway;

-- Create new policies

-- 1. Users can view their own pathway enrollments
CREATE POLICY "Users can view their own pathway enrollments"
ON user_pathway
FOR SELECT
USING (
  auth.uid() = user_id
  OR
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- 2. Only admins can insert pathway enrollments
CREATE POLICY "Admins can assign pathways"
ON user_pathway
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- 3. Users can update their own pathway (switch current)
CREATE POLICY "Users can update their own pathway"
ON user_pathway
FOR UPDATE
USING (
  auth.uid() = user_id
  OR
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- 4. Only admins can delete pathway enrollments
CREATE POLICY "Admins can delete pathway enrollments"
ON user_pathway
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- Verify policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'user_pathway';
