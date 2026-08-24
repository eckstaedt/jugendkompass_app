import 'dart:convert';

import 'package:jugendkompass_app/data/services/user_preferences_service.dart';

/// Local persistence for the "Bibel in 365 Tagen" reading plan.
///
/// Tracks:
/// - The date the user started the plan (used to compute "today's" day).
/// - Which reading items (chapter ranges) have been checked off per day.
///
/// Purely local (SharedPreferences) — no backend/account required, matching
/// how the app already stores other progress data (see
/// [UserPreferencesService.getReadingPlanProgress]).
class BibleReadingPlanService {
  static final BibleReadingPlanService instance = BibleReadingPlanService._internal();
  BibleReadingPlanService._internal();

  static const String _keyStartDate = 'bible_plan_start_date';
  static const String _keyCheckedReadings = 'bible_plan_checked_readings';
  static const String _keyHasStarted = 'bible_plan_has_started';

  /// Whether the user has already tapped "Bibelleseplan starten" once.
  /// Until then, the intro screen ("Die ganze Bibel in einem Jahr") is shown
  /// instead of the chapter overview.
  bool hasStartedPlan() {
    return UserPreferencesService.instance.getBool(_keyHasStarted) ?? false;
  }

  /// Marks the plan as started (today becomes day 1) and persists it.
  Future<void> startPlan() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await UserPreferencesService.instance.setString(_keyStartDate, today.toIso8601String());
    await UserPreferencesService.instance.setBool(_keyHasStarted, true);
  }

  /// Returns the date the plan was started, creating (and persisting) it as
  /// "today" if it doesn't exist yet (defensive fallback — normally set via
  /// [startPlan]).
  DateTime getOrCreateStartDate() {
    final stored = UserPreferencesService.instance.getString(_keyStartDate);
    if (stored != null) {
      final parsed = DateTime.tryParse(stored);
      if (parsed != null) return parsed;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    UserPreferencesService.instance.setString(_keyStartDate, today.toIso8601String());
    return today;
  }

  /// Computes the current day number (1-365, clamped) based on how many
  /// days have passed since the plan was started.
  int getCurrentDayNumber() {
    final start = getOrCreateStartDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceStart = today.difference(start).inDays;
    final dayNumber = daysSinceStart + 1;
    if (dayNumber < 1) return 1;
    if (dayNumber > 365) return 365;
    return dayNumber;
  }

  /// Returns the calendar date for a given plan day number, based on the
  /// plan's start date.
  DateTime getDateForDay(int dayNumber) {
    final start = getOrCreateStartDate();
    return start.add(Duration(days: dayNumber - 1));
  }

  /// Returns which reading-item indices are checked off for each day,
  /// keyed by day number.
  Map<int, Set<int>> getCheckedReadings() {
    final raw = UserPreferencesService.instance.getString(_keyCheckedReadings);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          int.parse(key),
          (value as List<dynamic>).map((e) => e as int).toSet(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveCheckedReadings(Map<int, Set<int>> data) async {
    final encoded = jsonEncode(
      data.map((key, value) => MapEntry(key.toString(), value.toList())),
    );
    await UserPreferencesService.instance.setString(_keyCheckedReadings, encoded);
  }

  /// Toggles whether a specific reading item (by index within that day) is
  /// checked off. Returns the updated map.
  Future<Map<int, Set<int>>> toggleReading(int dayNumber, int readingIndex) async {
    final data = getCheckedReadings();
    final daySet = Set<int>.from(data[dayNumber] ?? <int>{});

    if (daySet.contains(readingIndex)) {
      daySet.remove(readingIndex);
    } else {
      daySet.add(readingIndex);
    }

    data[dayNumber] = daySet;
    await _saveCheckedReadings(data);
    return data;
  }
}
