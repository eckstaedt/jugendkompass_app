import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/message_model.dart';
import 'package:jugendkompass_app/data/repositories/message_repository.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

/// Message repository provider
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return MessageRepository(supabase);
});

/// Messages list provider (Kurznachrichten)
final messagesListProvider = FutureProvider<List<MessageModel>>((ref) async {
  final repository = ref.watch(messageRepositoryProvider);
  return await repository.getMessageList(limit: 50);
});

/// Single message provider by ID (integer id)
final messageDetailProvider = FutureProvider.family<MessageModel?, String>(
  (ref, messageId) async {
    final repository = ref.watch(messageRepositoryProvider);
    return await repository.getMessageById(messageId);
  },
);

/// Single message provider by content_id (UUID)
final messageByContentIdProvider = FutureProvider.family<MessageModel?, String>(
  (ref, contentId) async {
    final repository = ref.watch(messageRepositoryProvider);
    return await repository.getMessageByContentId(contentId);
  },
);
