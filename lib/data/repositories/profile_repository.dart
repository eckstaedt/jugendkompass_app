import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../../core/constants/supabase_constants.dart';

class ProfileRepository {
  final SupabaseClient _supabaseClient;

  ProfileRepository(this._supabaseClient);

  /// Get profile by user ID
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from(SupabaseConstants.profilesTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Update profile
  Future<void> updateProfile(ProfileModel profile) async {
    try {
      await _supabaseClient
          .from(SupabaseConstants.profilesTable)
          .upsert(profile.toJson());
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Delete user data
  Future<void> deleteUserData(String userId) async {
    try {
      // Delete from profiles table (using user_id FK)
      await _supabaseClient
          .from(SupabaseConstants.profilesTable)
          .delete()
          .eq('user_id', userId);

      // Delete from reading_plans table if exists
      try {
        await _supabaseClient
            .from('reading_plans')
            .delete()
            .eq('user_id', userId);
      } catch (_) {
        // Table might not exist yet
      }
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }
}
