import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/message_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';

class MessageRepository {
  final SupabaseClient _supabase;

  MessageRepository(this._supabase);

  /// Fetch all messages (Kurznachrichten) with optional pagination
  Future<List<MessageModel>> getMessageList({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.messagesTable)
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der Kurznachrichten: $e');
    }
  }

  /// Fetch localized messages using Supabase RPC function.
  ///
  /// Uses get_messages_localized(lang) which returns translated title/message
  /// from content_translations. German (de) returns original content.
  Future<List<MessageModel>> getMessageListLocalized(
    String language, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      if (language == 'de') {
        return getMessageList(limit: limit, offset: offset);
      }

      final response = await _supabase.rpc(
        'get_messages_localized',
        params: {'lang': language},
      );

      final messages = (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return messages.skip(offset).take(limit).toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der lokalisierten Kurznachrichten: $e');
    }
  }

  /// Fetch a single message by ID (integer id from messages table)
  Future<MessageModel?> getMessageById(String id) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.messagesTable)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return MessageModel.fromJson(response);
    } catch (e) {
      throw Exception('Fehler beim Laden der Kurznachricht: $e');
    }
  }

  /// Fetch a single localized message by ID.
  Future<MessageModel?> getMessageByIdLocalized(String id, String language) async {
    try {
      if (language == 'de') {
        return getMessageById(id);
      }

      final baseMessage = await getMessageById(id);
      if (baseMessage == null || baseMessage.contentId == null) {
        return baseMessage;
      }

      final translations = await _supabase
          .from('content_translations')
          .select('field_name, value')
          .eq('content_id', baseMessage.contentId!)
          .eq('language', language);

      String? translatedTitle;
      String? translatedMessage;

      for (final row in translations as List) {
        final field = row['field_name'] as String;
        final value = row['value'] as String;

        if (field == 'title') translatedTitle = value;
        if (field == 'message') translatedMessage = value;
      }

      return baseMessage.copyWith(
        title: translatedTitle ?? baseMessage.title,
        message: translatedMessage ?? baseMessage.message,
      );
    } catch (e) {
      throw Exception('Fehler beim Laden der lokalisierten Kurznachricht: $e');
    }
  }

  /// Fetch a single message by content_id (UUID from content table)
  Future<MessageModel?> getMessageByContentId(String contentId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.messagesTable)
          .select()
          .eq('content_id', contentId)
          .maybeSingle();

      if (response == null) return null;

      return MessageModel.fromJson(response);
    } catch (e) {
      throw Exception('Fehler beim Laden der Kurznachricht: $e');
    }
  }

  /// Fetch a single localized message by content_id.
  Future<MessageModel?> getMessageByContentIdLocalized(String contentId, String language) async {
    try {
      if (language == 'de') {
        return getMessageByContentId(contentId);
      }

      final baseMessage = await getMessageByContentId(contentId);
      if (baseMessage == null) return null;

      return getMessageByIdLocalized(baseMessage.id, language);
    } catch (e) {
      throw Exception('Fehler beim Laden der lokalisierten Kurznachricht: $e');
    }
  }
}
