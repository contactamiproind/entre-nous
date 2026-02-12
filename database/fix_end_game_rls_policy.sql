-- Fix RLS policy for end_game_assignments to allow users to update their own completion status

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can update their own assignments" ON end_game_assignments;

-- Allow users to UPDATE their own assignment records (for marking as completed)
CREATE POLICY "Users can update their own assignments" ON end_game_assignments
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Allow users to INSERT their own assignment records (for upsert operation)
DROP POLICY IF EXISTS "Users can insert their own assignments" ON end_game_assignments;

CREATE POLICY "Users can insert their own assignments" ON end_game_assignments
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Verify the policies
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
WHERE tablename = 'end_game_assignments'
ORDER BY policyname;
