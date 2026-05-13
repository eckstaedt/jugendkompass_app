-- Create app_analytics table for tracking installs and app openings
CREATE TABLE IF NOT EXISTS app_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id text NOT NULL,
  event_type text NOT NULL CHECK (event_type IN ('install', 'app_open')),
  platform text NOT NULL DEFAULT 'unknown',
  app_version text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Create index on device_id for faster queries
CREATE INDEX IF NOT EXISTS idx_app_analytics_device_id ON app_analytics(device_id);

-- Create index on event_type for analytics queries
CREATE INDEX IF NOT EXISTS idx_app_analytics_event_type ON app_analytics(event_type);

-- Create index on created_at for time-based queries
CREATE INDEX IF NOT EXISTS idx_app_analytics_created_at ON app_analytics(created_at DESC);

-- Enable RLS
ALTER TABLE app_analytics ENABLE ROW LEVEL SECURITY;

-- Policy: Allow insert for anyone (anonymous users can track analytics)
CREATE POLICY "Allow insert for all users"
  ON app_analytics
  FOR INSERT
  TO public
  WITH CHECK (true);

-- Policy: Only admins can read analytics data
CREATE POLICY "Allow read for admins only"
  ON app_analytics
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Create a function to get analytics summary
CREATE OR REPLACE FUNCTION get_analytics_summary()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result json;
BEGIN
  -- Only admins can call this function
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin only';
  END IF;

  SELECT json_build_object(
    'total_installs', (SELECT COUNT(DISTINCT device_id) FROM app_analytics WHERE event_type = 'install'),
    'total_app_opens', (SELECT COUNT(*) FROM app_analytics WHERE event_type = 'app_open'),
    'unique_devices', (SELECT COUNT(DISTINCT device_id) FROM app_analytics),
    'installs_last_7_days', (
      SELECT COUNT(DISTINCT device_id)
      FROM app_analytics
      WHERE event_type = 'install'
      AND created_at >= NOW() - INTERVAL '7 days'
    ),
    'installs_last_30_days', (
      SELECT COUNT(DISTINCT device_id)
      FROM app_analytics
      WHERE event_type = 'install'
      AND created_at >= NOW() - INTERVAL '30 days'
    ),
    'app_opens_last_7_days', (
      SELECT COUNT(*)
      FROM app_analytics
      WHERE event_type = 'app_open'
      AND created_at >= NOW() - INTERVAL '7 days'
    ),
    'app_opens_last_30_days', (
      SELECT COUNT(*)
      FROM app_analytics
      WHERE event_type = 'app_open'
      AND created_at >= NOW() - INTERVAL '30 days'
    ),
    'avg_opens_per_device', (
      SELECT ROUND(AVG(open_count), 2)
      FROM (
        SELECT device_id, COUNT(*) as open_count
        FROM app_analytics
        WHERE event_type = 'app_open'
        GROUP BY device_id
      ) device_opens
    ),
    'platforms', (
      SELECT json_object_agg(platform, device_count)
      FROM (
        SELECT platform, COUNT(DISTINCT device_id) as device_count
        FROM app_analytics
        WHERE event_type = 'install'
        GROUP BY platform
      ) platform_stats
    )
  ) INTO result;

  RETURN result;
END;
$$;

COMMENT ON TABLE app_analytics IS 'Tracks app installs and app openings for analytics';
COMMENT ON COLUMN app_analytics.event_type IS 'Type of event: install (first launch) or app_open (subsequent launches)';
COMMENT ON COLUMN app_analytics.platform IS 'Platform: ios, android, or web';
COMMENT ON COLUMN app_analytics.app_version IS 'App version at the time of event';
