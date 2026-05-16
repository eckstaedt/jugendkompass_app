-- Create content_interactions table for tracking user content engagement
-- Anonymous tracking using device_id (similar to app_analytics)

CREATE TABLE content_interactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id text NOT NULL,
  content_type text NOT NULL,      -- 'post', 'video', 'audio', 'impulse', 'message'
  content_id text NOT NULL,        -- The content's ID
  content_title text,              -- Optional title for analytics
  platform text NOT NULL,          -- 'ios', 'android', 'web'
  app_version text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for efficient queries
CREATE INDEX idx_content_interactions_device ON content_interactions(device_id);
CREATE INDEX idx_content_interactions_type ON content_interactions(content_type);
CREATE INDEX idx_content_interactions_content ON content_interactions(content_id);
CREATE INDEX idx_content_interactions_created ON content_interactions(created_at);

-- RLS: Anyone can insert, only admins can read
ALTER TABLE content_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can insert content interactions"
  ON content_interactions
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Admins can read content interactions"
  ON content_interactions
  FOR SELECT
  USING (is_admin());
