import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';
import 'package:jugendkompass_app/data/models/app_announcement_model.dart';
import 'package:jugendkompass_app/data/services/supabase_service.dart';

/// Loads the currently active in-app announcement and remembers which ones the
/// user has dismissed on this device.
class AnnouncementRepository {
  static const _dismissedKey = 'dismissed_announcements';

  /// Returns the announcement to show right now, or null.
  Future<AppAnnouncement?> fetchAnnouncementToShow() async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final rows = await SupabaseService.instance.client
          .from(SupabaseConstants.appAnnouncementsTable)
          .select()
          .eq('is_active', true)
          .lte('starts_at', nowIso)
          .gt('ends_at', nowIso)
          .order('starts_at', ascending: false)
          .limit(5);

      final dismissed = await _dismissedIds();
      final now = DateTime.now();
      for (final row in rows) {
        final a = AppAnnouncement.fromJson(Map<String, dynamic>.from(row));
        if (!a.isActiveAt(now)) continue;
        if (a.showOnce && dismissed.contains(a.id)) continue;
        return a;
      }
    } catch (e) {
      // Never block the app because of an announcement.
      debugPrint('[Announcement] fetch failed: $e');
    }
    return null;
  }

  Future<void> markDismissed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_dismissedKey) ?? <String>[];
    if (!ids.contains(id)) {
      ids.add(id);
      // Keep the list small.
      if (ids.length > 50) ids.removeRange(0, ids.length - 50);
      await prefs.setStringList(_dismissedKey, ids);
    }
  }

  Future<Set<String>> _dismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_dismissedKey) ?? const <String>[]).toSet();
  }
}
