-- Create End Game configuration tables

-- Table for storing End Game configurations
CREATE TABLE IF NOT EXISTS end_game_configs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  level INTEGER CHECK (level >= 1 AND level <= 4),
  venue_data JSONB NOT NULL,
  items_data JSONB NOT NULL,
  is_active BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Table for assigning End Games to specific users
CREATE TABLE IF NOT EXISTS end_game_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  end_game_id UUID REFERENCES end_game_configs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  assigned_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(end_game_id, user_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_end_game_configs_level ON end_game_configs(level);
CREATE INDEX IF NOT EXISTS idx_end_game_configs_active ON end_game_configs(is_active);
CREATE INDEX IF NOT EXISTS idx_end_game_assignments_user ON end_game_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_end_game_assignments_config ON end_game_assignments(end_game_id);

-- Add RLS policies
ALTER TABLE end_game_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE end_game_assignments ENABLE ROW LEVEL SECURITY;

-- Admin can do everything
CREATE POLICY "Admins can manage end game configs" ON end_game_configs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can manage end game assignments" ON end_game_assignments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Users can view their assigned End Games
CREATE POLICY "Users can view assigned end games" ON end_game_configs
  FOR SELECT USING (
    id IN (
      SELECT end_game_id FROM end_game_assignments
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view their assignments" ON end_game_assignments
  FOR SELECT USING (user_id = auth.uid());

-- Verification queries
SELECT 'End Game tables created successfully' AS status;
SELECT COUNT(*) as config_count FROM end_game_configs;
SELECT COUNT(*) as assignment_count FROM end_game_assignments;
