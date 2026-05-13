# App Analytics Implementation

## Overview
Simple analytics tracking for app installs and app openings without any third-party analytics services. All data is stored in Supabase.

## Database Schema

### Table: `app_analytics`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| device_id | text | Anonymous device identifier (UUID) |
| event_type | text | Event type: 'install' or 'app_open' |
| platform | text | Platform: 'ios', 'android', or 'web' |
| app_version | text | App version at time of event (e.g., "2.0.1+43") |
| created_at | timestamptz | Timestamp of event |

**Indexes:**
- `device_id` for fast device lookups
- `event_type` for filtering by event
- `created_at` for time-based queries

**RLS Policies:**
- Anyone can insert (anonymous analytics)
- Only admins can read data

## Analytics Function

### `get_analytics_summary()`
PostgreSQL function that returns analytics data (admin-only):

```json
{
  "total_installs": 1234,
  "total_app_opens": 5678,
  "unique_devices": 1234,
  "installs_last_7_days": 45,
  "installs_last_30_days": 180,
  "app_opens_last_7_days": 890,
  "app_opens_last_30_days": 3456,
  "avg_opens_per_device": 4.6,
  "platforms": {
    "ios": 800,
    "android": 434
  }
}
```

## Implementation

### AnalyticsService (`lib/core/services/analytics_service.dart`)

**Methods:**
- `trackInstallIfNeeded()` - Tracks first launch only (checks local storage)
- `trackAppOpen()` - Tracks every app launch
- `getAnalyticsSummary()` - Admin-only, fetches analytics data

**Features:**
- Uses device_id from `DeviceRegistrationService` for anonymity
- Stores install tracking state in `SharedPreferences` 
- Never throws errors (silent failure to prevent app crashes)
- Tracks app version for each event

### Integration

Analytics are tracked on app startup in `main.dart`:

```dart
// Track app analytics (install on first launch, app open on every launch)
await AnalyticsService.instance.trackInstallIfNeeded();
await AnalyticsService.instance.trackAppOpen();
```

**Timing:**
- Runs after Supabase initialization
- Runs before UI is shown
- Non-blocking (errors are caught silently)

## Privacy

- **Anonymous**: Uses random UUID, no personal data
- **Device-based**: Same device = same device_id
- **No tracking across devices**: Uninstall/reinstall = new device_id
- **Minimal data**: Only event type, platform, and timestamp

## Deployment

1. **Apply migration:**
   ```bash
   supabase db push
   # or
   supabase migration up
   ```

2. **Migration file:**
   `supabase/migrations/create_app_analytics.sql`

## Usage Example (Admin)

To view analytics in your admin panel or backend:

```dart
try {
  final analytics = await AnalyticsService.instance.getAnalyticsSummary();
  print('Total installs: ${analytics['total_installs']}');
  print('App opens today: ${analytics['app_opens_last_7_days']}');
} catch (e) {
  // User is not admin or error occurred
}
```

## Metrics Tracked

### Install Metrics
- **Total installs**: Unique devices that installed the app
- **New installs (7d)**: Fresh installs in last 7 days
- **New installs (30d)**: Fresh installs in last 30 days
- **Platform distribution**: iOS vs Android vs Web

### Engagement Metrics
- **Total app opens**: All app launch events
- **App opens (7d)**: Recent engagement
- **App opens (30d)**: Monthly engagement
- **Average opens per device**: Engagement frequency
- **Unique active devices**: Total devices that have opened the app

## Notes

- First version tracked = app version at install time
- Reinstalling the app = new install event (different device_id)
- Analytics never block app startup
- Data retention is indefinite (no auto-cleanup)
- Query performance optimized via indexes
