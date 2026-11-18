import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/core/services/device_registration_service.dart';

/// Holds the current like state for a piece of content.
class LikeState {
  final bool liked;
  final int likeCount;

  const LikeState({required this.liked, required this.likeCount});

  LikeState copyWith({bool? liked, int? likeCount}) =>
      LikeState(
        liked: liked ?? this.liked,
        likeCount: likeCount ?? this.likeCount,
      );
}

/// Service that talks to the `likes` table via Supabase.
class LikeService {
  static final LikeService instance = LikeService._internal();
  LikeService._internal();

  final _client = Supabase.instance.client;

  String get _deviceId => DeviceRegistrationService.instance.deviceId;

  /// Returns the current like state for a content item.
  Future<LikeState> getLikeState(String contentId, String contentType) async {
    try {
      // Total likes
      final countRes = await _client
          .from('likes')
          .select('id')
          .eq('content_id', contentId)
          .eq('content_type', contentType);
      final count = (countRes as List).length;

      // Whether this device liked it
      final userRes = await _client
          .from('likes')
          .select('id')
          .eq('content_id', contentId)
          .eq('content_type', contentType)
          .eq('device_id', _deviceId);
      final liked = (userRes as List).isNotEmpty;

      return LikeState(liked: liked, likeCount: count);
    } catch (e) {
      debugPrint('[LikeService] getLikeState error: $e');
      return const LikeState(liked: false, likeCount: 0);
    }
  }

  /// Toggles the like for this device. Returns the new state.
  Future<LikeState> toggleLike(String contentId, String contentType) async {
    try {
      final res = await _client.rpc('toggle_like', params: {
        'p_content_id': contentId,
        'p_content_type': contentType,
        'p_device_id': _deviceId,
      });
      final row = (res as List).first as Map<String, dynamic>;
      return LikeState(
        liked: row['liked'] as bool,
        likeCount: row['like_count'] as int,
      );
    } catch (e) {
      debugPrint('[LikeService] toggleLike error: $e');
      rethrow;
    }
  }
}
