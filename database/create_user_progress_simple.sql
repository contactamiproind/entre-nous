-- Drop the table if it exists (to remove problematic foreign keys)
DROP TABLE IF EXISTS user_progress;

-- Create user_progress table WITHOUT foreign key constraints
CREATE TABLE user_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL,
  current_pathway_id UUID,
  current_level INT DEFAULT 1,
  total_score INT DEFAULT 0,
  completed_assignments INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert record for the user
INSERT INTO user_progress (user_id, current_pathway_id, current_level)
VALUES ('fe3c162a-8b43-4a79-b4ff-d32294429781', '32d2764f-ed76-40db-8886-bcf5923f91a1', 1);

-- Verify it was created
SELECT * FROM user_progress WHERE user_id = 'fe3c162a-8b43-4a79-b4ff-d32294429781';
