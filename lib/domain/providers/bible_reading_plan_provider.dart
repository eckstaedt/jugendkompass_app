import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/services/device_registration_service.dart';
import 'package:jugendkompass_app/data/models/bible_reading_plan_model.dart';
import 'package:jugendkompass_app/data/services/bible_reading_plan_generator.dart';
import 'package:jugendkompass_app/data/services/bible_reading_plan_service.dart';

/// The full, static 365-day reading plan (generated once, memoized).
final bibleReadingPlanProvider = Provider<List<BibleReadingDay>>((ref) {
  return BibleReadingPlanGenerator.generate();
});

/// Today's day number (1-365) based on when the user started the plan.
final bibleReadingTodayDayNumberProvider = Provider<int>((ref) {
  return BibleReadingPlanService.instance.getCurrentDayNumber();
});

/// Whether the user has already started the plan (tapped "Bibelleseplan
/// starten"). While false, the intro screen is shown instead of the
/// chapter overview.
class BibleReadingHasStartedNotifier extends StateNotifier<bool> {
  BibleReadingHasStartedNotifier() : super(BibleReadingPlanService.instance.hasStartedPlan());

  Future<void> start() async {
    await BibleReadingPlanService.instance.startPlan();
    state = true;
    // Enable the daily 06:30 reminder push for this device.
    unawaited(DeviceRegistrationService.instance.updateBiblePlanStarted(true));
  }
}

final bibleReadingHasStartedProvider =
    StateNotifierProvider<BibleReadingHasStartedNotifier, bool>(
  (ref) => BibleReadingHasStartedNotifier(),
);


/// Manages which reading items are checked off, per day.
///
/// State: a map from day number to the set of checked reading indices.
class BibleReadingCheckedNotifier extends StateNotifier<Map<int, Set<int>>> {
  BibleReadingCheckedNotifier() : super(BibleReadingPlanService.instance.getCheckedReadings());

  /// Toggles a reading item and returns whether it is now checked.
  Future<bool> toggle(int dayNumber, int readingIndex) async {
    state = await BibleReadingPlanService.instance.toggleReading(dayNumber, readingIndex);
    return (state[dayNumber] ?? const {}).contains(readingIndex);
  }

  bool isChecked(int dayNumber, int readingIndex) {
    return (state[dayNumber] ?? const {}).contains(readingIndex);
  }

  /// Whether every reading item for [dayNumber] (out of [totalReadings]) is
  /// checked off.
  bool isDayCompleted(int dayNumber, int totalReadings) {
    final checked = state[dayNumber];
    if (checked == null) return false;
    return checked.length >= totalReadings;
  }

  /// Total number of fully-completed days across the whole plan.
  int completedDaysCount(List<BibleReadingDay> plan) {
    return plan.where((day) => isDayCompleted(day.dayNumber, day.chapters.length)).length;
  }
}

final bibleReadingCheckedProvider =
    StateNotifierProvider<BibleReadingCheckedNotifier, Map<int, Set<int>>>(
  (ref) => BibleReadingCheckedNotifier(),
);
