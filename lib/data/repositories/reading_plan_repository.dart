import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reading_plan_model.dart';
import '../services/user_preferences_service.dart';

class ReadingPlanRepository {
  final SupabaseClient _supabaseClient;

  ReadingPlanRepository(this._supabaseClient);

  /// Get user's reading plan (from local storage or Supabase)
  Future<ReadingPlanModel?> getUserReadingPlan(String? userId) async {
    // Try local storage first
    final localPlan = _getLocalReadingPlan();
    if (localPlan != null) {
      return localPlan;
    }

    // If user is authenticated, try Supabase
    if (userId != null) {
      try {
        final response = await _supabaseClient
            .from('reading_plans')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null) {
          final plan = ReadingPlanModel.fromJson(response);
          // Cache locally
          await _saveLocalReadingPlan(plan);
          return plan;
        }
      } catch (e) {
        // Table might not exist yet, continue with local creation
      }
    }

    // Create new plan if none exists
    return null;
  }

  /// Create a new reading plan
  Future<ReadingPlanModel> createReadingPlan(String? userId) async {
    final now = DateTime.now();
    final plan = ReadingPlanModel(
      id: userId ?? 'local_${now.millisecondsSinceEpoch}',
      currentWeek: 1,
      days: List.generate(
        7,
        (index) => ReadingDay(
          dayNumber: index + 1,
          isCompleted: false,
        ),
      ),
      startDate: now,
    );

    // Save locally
    await _saveLocalReadingPlan(plan);

    // Save to Supabase if authenticated
    if (userId != null) {
      try {
        await _supabaseClient.from('reading_plans').upsert({
          'id': plan.id,
          'user_id': userId,
          'current_week': plan.currentWeek,
          'days': jsonEncode(plan.days.map((d) => d.toJson()).toList()),
          'start_date': plan.startDate.toIso8601String(),
        });
      } catch (e) {
        // Table might not exist yet, continue with local only
      }
    }

    return plan;
  }

  /// Update day completion
  Future<void> updateDayCompletion(
    String? userId,
    int week,
    int day,
    bool completed,
  ) async {
    // Get current plan
    final currentPlan = await getUserReadingPlan(userId);
    if (currentPlan == null) return;

    // Update day
    final updatedDays = currentPlan.days.map((d) {
      if (d.dayNumber == day) {
        return d.copyWith(
          isCompleted: completed,
          completedAt: completed ? DateTime.now() : null,
        );
      }
      return d;
    }).toList();

    final updatedPlan = currentPlan.copyWith(
      days: updatedDays,
      lastUpdatedAt: DateTime.now(),
    );

    // Save locally
    await _saveLocalReadingPlan(updatedPlan);

    // Save to Supabase if authenticated
    if (userId != null) {
      try {
        await _supabaseClient.from('reading_plans').update({
          'days': jsonEncode(updatedDays.map((d) => d.toJson()).toList()),
          'last_updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', userId);
      } catch (e) {
        // Table might not exist yet, continue with local only
      }
    }
  }

  /// Get local reading plan from SharedPreferences
  ReadingPlanModel? _getLocalReadingPlan() {
    final jsonString = UserPreferencesService.instance.getReadingPlanProgress();
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ReadingPlanModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Save reading plan to local storage
  Future<void> _saveLocalReadingPlan(ReadingPlanModel plan) async {
    final jsonString = jsonEncode(plan.toJson());
    await UserPreferencesService.instance.saveReadingPlanProgress(jsonString);
  }
}
