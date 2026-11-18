import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

/// Streams the live view count for a post.
///
/// Uses a [StreamController] that:
/// 1. Emits the initial count from [post_view_counts] immediately.
/// 2. Subscribes to Supabase Realtime changes on that row so every user sees
///    the number update in real-time whenever someone opens the post.
///
/// The [contentId] parameter is the post's own UUID (= `posts.id`), which is
/// what [ContentInteractionService] stores in `content_interactions.content_id`.
final postViewCountProvider =
    StreamProvider.family<int, String>((ref, contentId) {
  final supabase = ref.read(supabaseProvider);
  final controller = StreamController<int>();

  // --- Initial fetch ---
  supabase
      .from('post_view_counts')
      .select('view_count')
      .eq('content_id', contentId)
      .maybeSingle()
      .then((row) {
    if (!controller.isClosed) {
      controller.add((row?['view_count'] as int?) ?? 0);
    }
  }).catchError((_) {
    if (!controller.isClosed) controller.add(0);
  });

  // --- Realtime subscription ---
  final channel = supabase
      .channel('post_view_count_$contentId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'post_view_counts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'content_id',
          value: contentId,
        ),
        callback: (payload) {
          final newRecord = payload.newRecord;
          final count = (newRecord['view_count'] as int?) ?? 0;
          if (!controller.isClosed) controller.add(count);
        },
      )
      .subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});
