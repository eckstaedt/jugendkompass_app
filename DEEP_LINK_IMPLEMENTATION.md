# Deep Link Implementation for Push Notifications

## Overview
This implementation enables users to navigate directly to specific content (posts, videos, verses, impulses, etc.) when tapping push notifications.

## Changes Made

### 1. DeepLinkService (`lib/core/services/deep_link_service.dart`)
New service that handles navigation to content from notification data payloads.

**Features:**
- Maps content types to appropriate screens (post → PostDetailScreen, video → VideoPlayerScreen, etc.)
- Fetches content data before navigation using Riverpod providers
- Shows verse in a dialog (since there's no dedicated verse detail screen)
- Handles errors gracefully with debug logging

**Supported content types:**
- `post` → PostDetailScreen
- `video` → VideoPlayerScreen  
- `verse` → Dialog with verse text
- `impulse`, `message`, `poll` → ContentDetailScreen (generic)

### 2. FCMService Updates (`lib/core/services/fcm_service.dart`)
Enhanced to handle notification taps from all app states.

**New features:**
- `onNotificationTap` callback property for navigation
- Handlers for background/terminated notification taps (`FirebaseMessaging.onMessageOpenedApp`, `getInitialMessage`)
- Foreground notification tap handling via `flutter_local_notifications` 
- Payload serialization for local notifications (format: `contentType|contentId`)

**App states covered:**
- Foreground: User sees notification, taps it
- Background: App minimized, user taps notification
- Terminated: App closed, user taps notification to launch app

### 3. App Initialization (`lib/app.dart`)
Wired up the notification tap handler in `_AppState`.

**Implementation:**
- Sets `FCMService().onNotificationTap` callback in `initState`
- Calls `DeepLinkService.instance.handleNotificationTap()` when notification is tapped
- Uses `WidgetsBinding.instance.addPostFrameCallback` to ensure navigator is ready

### 4. FCM Service Initialization (`lib/main.dart`)
Added FCM initialization on app startup (mobile only).

```dart
if (!kIsWeb) {
  await FCMService().init();
}
```

### 5. Server-Side: Push Notification Data Payload

#### `supabase/functions/send-push-notification/index.ts`
Added `data` field to FCM messages with deep link information:

```typescript
data: {
  contentType: notification.data.contentType,
  contentId: notification.data.contentId,
}
```

**Updated `getNotificationContent()` to return:**
- `contentType`: Type of content (post, video, verse, impulse, etc.)
- `contentId`: UUID of the content
- Added `verse_of_the_day` table support
- Added verse notification translations in 5 languages

#### `supabase/functions/send-daily-verse-notification/index.ts`
Updated to include deep link data:

```typescript
data: {
  contentType: 'verse',
  contentId: verseData.id,
}
```

### 6. Provider Updates

#### `lib/domain/providers/post_provider.dart`
Added `postByIdProvider` (alias for `postDetailProvider`) for consistency.

#### `lib/domain/providers/verse_provider.dart`
Added `verseByIdProvider` to fetch a specific verse by ID.

#### `lib/data/repositories/verse_repository.dart`
Added `getVerseById()` method to support verse deep linking.

## Data Flow

### Push Notification → Deep Link Navigation

1. **Server sends notification** with data payload:
   ```json
   {
     "notification": {
       "title": "Neuer Artikel",
       "body": "Check out this new post!"
     },
     "data": {
       "contentType": "post",
       "contentId": "uuid-123"
     }
   }
   ```

2. **User taps notification** → FCM fires appropriate handler based on app state

3. **FCMService** calls `onNotificationTap(data)` callback

4. **App** forwards to `DeepLinkService.handleNotificationTap()`

5. **DeepLinkService** fetches content via Riverpod provider

6. **Navigator** pushes appropriate detail screen

## Testing Checklist

- [ ] Test post notification → PostDetailScreen
- [ ] Test video notification → VideoPlayerScreen
- [ ] Test verse notification → Dialog display
- [ ] Test impulse/message notification → ContentDetailScreen
- [ ] Test notification tap from foreground state
- [ ] Test notification tap from background state
- [ ] Test notification tap from terminated state (cold start)
- [ ] Test with non-existent content ID (error handling)
- [ ] Test on iOS
- [ ] Test on Android
- [ ] Verify verse notifications show localized content

## Notes

- Verse notifications show a dialog instead of navigating to a screen (no dedicated verse detail screen exists)
- The dialog includes translation support via `translateVerseProvider`
- All navigation is done via standard `Navigator.push()` to maintain compatibility with the persistent bottom navbar
- Deep links only work on mobile (iOS/Android), not on web
