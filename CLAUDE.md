# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Jugendkompass is a Flutter mobile app (iOS/Android) providing religious youth content including posts, daily verses, impulses, videos, podcasts, and polls. Backend is Supabase (PostgreSQL + Storage + Edge Functions), state management via Riverpod, navigation via MaterialApp with custom persistent bottom navbar.

## Development Commands

### Setup
```bash
flutter pub get                    # Install dependencies
```

### Build & Run
```bash
flutter run                        # Run on connected device/emulator
flutter run -d chrome              # Run on web
flutter run --release              # Release build
flutter build apk                  # Build Android APK
flutter build ios                  # Build iOS
```

### Code Generation
Riverpod providers and JSON serialization use code generation:
```bash
dart run build_runner build --delete-conflicting-outputs     # Generate once
dart run build_runner watch --delete-conflicting-outputs     # Watch mode
```

### Testing & Linting
```bash
flutter analyze                    # Run static analysis
flutter test                       # Run tests
```

### Firebase & App Icons
```bash
# App icons already configured in flutter_launcher_icons.yaml
flutter pub run flutter_launcher_icons:main

# Firebase config is pre-generated in firebase_options.dart
```

## Architecture

### Layer Structure
```
lib/
├── core/              # Cross-cutting concerns
│   ├── config/        # App theme, design tokens, environment config
│   ├── constants/     # Supabase table/field constants
│   ├── localization/  # i18n system (German/English)
│   ├── services/      # FCM, notifications, device registration, home widgets
│   └── utils/         # HTML parsing utilities
├── data/              # Data layer
│   ├── models/        # Plain Dart data classes for entities
│   ├── repositories/  # Supabase query logic per entity
│   └── services/      # SupabaseService, favorites, preferences, audio
├── domain/            # Business logic
│   └── providers/     # Riverpod providers (state management)
└── presentation/      # UI layer
    ├── navigation/    # Bottom navbar, route observers, mini player overlay
    └── screens/       # Feature-based screen folders
```

### State Management with Riverpod
- **Providers** in `lib/domain/providers/` manage state (e.g., `post_provider.dart`, `audio_player_provider.dart`)
- Use `@riverpod` annotation for code-generated providers (requires `build_runner`)
- Access providers with `ref.watch()` in widgets, `ref.read()` for one-time reads
- Example: `final posts = ref.watch(postsProvider);`

### Data Flow
1. **Repositories** (`lib/data/repositories/`) query Supabase and return raw JSON/maps
2. **Models** (`lib/data/models/`) parse JSON into typed Dart objects
3. **Providers** (`lib/domain/providers/`) expose models to UI with caching/refresh logic
4. **Screens** (`lib/presentation/screens/`) consume providers via `ConsumerWidget` or `ConsumerStatefulWidget`

### Supabase Integration
- Initialized in `main.dart` via `SupabaseService.initialize()`
- Credentials loaded from `dotenv` file (see `.env`)
- Database schema documented in `supabase.md` (tables: `users`, `posts`, `impulses`, `verse_of_the_day`, `videos`, `polls`, `content`, etc.)
- RLS policies: admins see all, users see published content + own data
- Storage buckets: `posts`, `impulses`, `audios`, `videos`, `Ausgaben`, `pdf`, etc.
- Key functions: `is_admin()`, `increment_poll_votes()`, content triggers auto-create `content` table entries
- `content_feed` view aggregates all content types

### Navigation System
- **Custom persistent bottom navbar** rendered in `MaterialApp.builder` overlay (not using Navigator 2.0 or go_router for tabs)
- Five tabs: Home, Kiosk, Podcast, Videos, Menu
- Tab state managed by `bottomNavIndexProvider`
- Detail screens pushed via `Navigator.push()` on top of `BottomNavScreen`
- Bottom navbar auto-hides on video/full-player routes via `FullPlayerRouteObserver`
- Mini player bar sits above navbar when audio is playing (managed in `_MiniPlayerScaffold`)

### Audio Playback
- `just_audio` package with `just_audio_background` for lock-screen controls
- State in `audio_player_provider.dart` (current audio, play/pause, progress)
- Mini player bar (`mini_player_bar.dart`) shown persistently across all routes when audio is active
- Expands to full player (`podcast_player_screen.dart`) on tap
- Web support via `WebAudioController` for browser media session API

### Theming & Design Tokens
- **Design system** centralized in `lib/core/config/design_tokens.dart`
- iOS 26-inspired "Liquid Glass" aesthetic: large border radii (40px cards, 32px containers), backdrop blur, translucent glass backgrounds
- Light/dark mode support: `DesignTokens.getAppBackground(brightness)`, `DesignTokens.getTextPrimary(brightness)`, etc.
- Theme toggle via `themeModeProvider`
- **Always use DesignTokens** for colors, radii, spacing, shadows — avoid hardcoded values
- Card borders: `DesignTokens.cardBorder(brightness)` for consistent 1px contrast
- Glass backgrounds: `DesignTokens.getGlassBackground(brightness, opacity)` with `glassBlurSigma` for backdrop blur
- Bottom padding for overlays: `overlayPaddingBase` (navbar only) or `overlayPaddingWithMiniPlayer` (navbar + mini player)

### Localization
- Translations in `lib/core/localization/app_translations.dart` (German/English map)
- Access via `context.tr('key')` extension on `BuildContext`
- Language toggle via `languageProvider`
- Date formatting initialized for German (`de_DE`) in `main.dart`

### Push Notifications & Firebase
- Firebase Cloud Messaging initialized in `main.dart` and `FCMService`
- Device tokens registered to Supabase via `DeviceRegistrationService`
- Notifications for daily verses and new content (toggle in user prefs)
- Background message handler: `firebaseMessagingBackgroundHandler`
- Home widgets (iOS): `HomeWidgetService` for lock-screen verse display

### Services Overview
- **SupabaseService**: Singleton client wrapper
- **UserPreferencesService**: SharedPreferences wrapper (onboarding, theme, language, notifications)
- **FavoritesService**: Local favorites storage (posts, verses)
- **ImageCacheService**: Configure Flutter's image cache size
- **FCMService**: Firebase push notifications
- **DeviceRegistrationService**: Register device token with Supabase
- **HomeWidgetService**: iOS home screen widget updates
- **WebAudioController**: Browser media session controls

## Content Types
All content is unified via the `content` table (UUID FK in `posts`, `impulses`, `verse_of_the_day`, `videos`, `messages`, `polls`). Content feed aggregates all types via `content_feed` view.

- **Posts**: Articles with title, body, category, edition, optional audio, image
- **Impulses**: Daily inspirational posts with date, image
- **Verse of the Day**: Daily Bible verse with reference
- **Videos**: YouTube/direct video URLs with title, description, thumbnail
- **Podcasts**: Audio files with metadata (title, duration, artwork)
- **Messages**: Admin-posted messages with optional image
- **Polls**: Questions with options, voting system

## Key Patterns

### Creating a new screen
1. Add screen file to `lib/presentation/screens/<feature>/`
2. Use `ConsumerWidget` or `ConsumerStatefulWidget` to access providers
3. Apply `DesignTokens` for colors, spacing, radii
4. Add bottom padding for persistent navbar: `DesignTokens.overlayPaddingBase` or `overlayPaddingWithMiniPlayer`
5. Use `context.tr('key')` for translated strings

### Adding a new content type
1. Define model in `lib/data/models/`
2. Create repository in `lib/data/repositories/` with Supabase queries
3. Create provider in `lib/domain/providers/` to expose data
4. Add Supabase trigger (if needed) to auto-create `content` table entry (see `handle_impulse_content()` etc.)
5. Update `content_feed` view to include new type

### Working with Supabase
- Always reference `supabase.md` for table schema and RLS rules
- Use `SupabaseService.instance.client` to access Supabase client
- Remember: admins can CRUD all, users see published content only
- Storage bucket URLs are public; use `getPublicUrl()` for images/audio/video

### Styling with DesignTokens
```dart
Container(
  decoration: BoxDecoration(
    color: DesignTokens.getCardBackground(brightness),
    borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
    border: DesignTokens.cardBorder(brightness),
    boxShadow: [DesignTokens.shadowLargeCard],
  ),
)
```

### Glass effect containers
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
  child: BackdropFilter(
    filter: ImageFilter.blur(
      sigmaX: DesignTokens.glassBlurSigma,
      sigmaY: DesignTokens.glassBlurSigma,
    ),
    child: Container(
      decoration: BoxDecoration(
        color: DesignTokens.getGlassBackground(brightness, 0.18),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
        border: Border.all(
          color: brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.10),
          width: 1.5,
        ),
      ),
      child: // your content
    ),
  ),
)
```

## Environment & Configuration

### Required files
- `.env` / `dotenv`: Contains `SUPABASE_URL` and `SUPABASE_ANON_KEY` (loaded via `flutter_dotenv`)
- `firebase_options.dart`: Auto-generated Firebase config (do not edit manually)
- `assets/images/`: App images referenced in `pubspec.yaml`

### Supabase Project
- Project ID: `vdcdibvclaulqxfjyzpq`
- URL: `https://vdcdibvclaulqxfjyzpq.supabase.co`
- See `supabase.md` for complete schema

## Common Pitfalls
- **Don't forget bottom padding**: Persistent navbar/mini player will cover content. Use `DesignTokens.overlayPaddingBase` or `overlayPaddingWithMiniPlayer`.
- **Always check brightness**: Use `Theme.of(context).brightness` and `DesignTokens.getX(brightness)` for dark mode compatibility.
- **Run build_runner after modifying providers**: Riverpod code generation required for `@riverpod` annotated providers.
- **Respect RLS policies**: Users can't write to admin-only tables (posts, editions, etc.). Test with non-admin accounts.
- **Use context.tr() for strings**: Hard-coded German/English strings break localization.
- **Audio state is global**: `currentAudioProvider` persists across tab switches. Don't create separate audio players per screen.
