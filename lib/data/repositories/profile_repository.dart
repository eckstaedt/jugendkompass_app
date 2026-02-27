import 'dart:io';
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

  /// Upload avatar image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadAvatar(String userId, File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // Upload to Supabase Storage
      await _supabaseClient.storage
          .from('profiles')
          .upload(filePath, imageFile);

      // Get public URL
      final publicUrl = _supabaseClient.storage
          .from('profiles')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  /// Delete avatar image from Supabase Storage
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('profiles');

      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('Invalid avatar URL');
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Delete from storage
      await _supabaseClient.storage
          .from('profiles')
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete avatar: $e');
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
