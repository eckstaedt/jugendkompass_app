# Deployment Checklist

## Recent Changes Summary

### 1. Deep Link Implementation (Push Notifications)
Navigate directly to content when tapping push notifications.

### 2. Analytics Tracking
Track app installs and openings anonymously.

---

## Deployment Steps

### Step 1: Apply Database Migrations

Run the analytics migration to create the `app_analytics` table:

```bash
cd supabase

# Option A: Push all pending migrations
supabase db push

# Option B: Apply specific migration
supabase migration up
```

**Migration file:** `supabase/migrations/create_app_analytics.sql`

### Step 2: Verify Database

Check that the new table and function were created:

```sql
-- Check table exists
SELECT * FROM app_analytics LIMIT 1;

-- Test analytics function (as admin)
SELECT get_analytics_summary();
```

### Step 3: Update Supabase Edge Functions

The push notification functions were updated to include deep link data:

```bash
cd supabase/functions

# Deploy send-push-notification function
supabase functions deploy send-push-notification

# Deploy send-daily-verse-notification function  
supabase functions deploy send-daily-verse-notification
```

### Step 4: Test Deep Linking

**Test Scenarios:**
1. Send a test post notification → Should open PostDetailScreen
2. Send a test video notification → Should open VideoPlayerScreen
3. Send a test verse notification → Should show verse dialog
4. Test from different app states:
   - Foreground (app open)
   - Background (app minimized)
   - Terminated (app closed, cold start)

**Test Command (if you have admin access):**
```bash
# Trigger a test notification via Supabase webhook
# or create a test post/video/verse in admin panel
```

### Step 5: Test Analytics

**Test Flow:**
1. Uninstall app completely
2. Reinstall and launch → Should track 1 install + 1 app_open
3. Close and reopen app → Should track another app_open (NO new install)
4. Check data in Supabase:
   ```sql
   SELECT * FROM app_analytics ORDER BY created_at DESC LIMIT 10;
   ```

**Expected Results:**
- First launch: 2 events (install + app_open)
- Subsequent launches: 1 event each (app_open only)
- All events have device_id, platform, app_version

### Step 6: Build and Release

```bash
# Update version in pubspec.yaml if needed
# Current version: 2.0.1+43

# Build for iOS
flutter build ios --release

# Build for Android
flutter build appbundle --release
# or
flutter build apk --release
```

---

## Verification Checklist

### Deep Linking
- [ ] Post notifications navigate to PostDetailScreen
- [ ] Video notifications navigate to VideoPlayerScreen
- [ ] Verse notifications show dialog with translated content
- [ ] Impulse/message notifications navigate to ContentDetailScreen
- [ ] Works from foreground state
- [ ] Works from background state
- [ ] Works from terminated state (cold start)

### Analytics
- [ ] Migration applied successfully
- [ ] Table `app_analytics` exists
- [ ] Function `get_analytics_summary()` works
- [ ] Install tracked on first launch only
- [ ] App opens tracked on every launch
- [ ] device_id matches across events
- [ ] Platform correctly identified (ios/android/web)
- [ ] App version captured correctly

### Edge Functions
- [ ] `send-push-notification` deployed with data payload
- [ ] `send-daily-verse-notification` deployed with data payload
- [ ] Notifications include contentType and contentId

---

## Rollback Instructions

If issues occur:

### Rollback Analytics
```sql
-- Drop the table and function
DROP FUNCTION IF EXISTS get_analytics_summary();
DROP TABLE IF EXISTS app_analytics CASCADE;
```

### Rollback Deep Linking
1. Revert FCMService changes
2. Revert app.dart changes
3. Remove DeepLinkService file
4. Redeploy old edge function versions

---

## Monitoring

### Check Analytics Data
```sql
-- Total installs
SELECT COUNT(DISTINCT device_id) FROM app_analytics WHERE event_type = 'install';

-- Total app opens
SELECT COUNT(*) FROM app_analytics WHERE event_type = 'app_open';

-- Recent activity
SELECT event_type, platform, COUNT(*) 
FROM app_analytics 
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY event_type, platform;
```

### Check Deep Link Logs
Look for these debug logs in app:
```
[DeepLink] Navigating to post with id: ...
[FCM] Notification tapped: ...
```

---

## Known Limitations

### Deep Linking
- Web platform not fully tested (push notifications may not work)
- Verse notifications show dialog instead of full screen (no dedicated verse detail screen)

### Analytics
- Reinstalling app creates new device_id (counts as new install)
- No user identification (fully anonymous)
- No event deduplication (rapid app opens count separately)
- Admin-only analytics access (regular users can't view stats)

---

## Support

For issues or questions:
1. Check logs: `flutter run` in debug mode
2. Check Supabase logs: Supabase Dashboard → Logs
3. Check Edge Function logs: Supabase Dashboard → Edge Functions → Logs
4. Review documentation: `ANALYTICS.md`, `DEEP_LINK_IMPLEMENTATION.md`
