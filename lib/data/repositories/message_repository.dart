import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/message_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';
import 'package:jugendkompass_app/data/services/content_localizer.dart';

class MessageRepository {
  final SupabaseClient _supabase;

  MessageRepository(this._supabase) : _localizer = ContentLocalizer.forClient(_supabase);

  final ContentLocalizer _localizer;

  static const _fields = {'title': 'title', 'message': 'message'};

  Future<List<MessageModel>> _toLocalizedModels(dynamic response, String language) async {
    final rows = (response as List).map((json) => Map<String, dynamic>.from(json as Map)).toList();
    await _localizer.localizeContentRows(rows, language, fields: _fields);
    return rows.map(MessageModel.fromJson).toList();
  }

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

  /// Fetch localized messages (German rows + translation overlay).
  Future<List<MessageModel>> getMessageListLocalized(
    String language, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.messagesTable)
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return _toLocalizedModels(response, language);
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
      final response = await _supabase
          .from(SupabaseConstants.messagesTable)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      final models = await _toLocalizedModels([response], language);
      return models.first;
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
      final response = await _supabase
          .from(SupabaseConstants.messagesTable)
          .select()
          .eq('content_id', contentId)
          .maybeSingle();
      if (response == null) return null;
      final models = await _toLocalizedModels([response], language);
      return models.first;
    } catch (e) {
      throw Exception('Fehler beim Laden der lokalisierten Kurznachricht: $e');
    }
  }
}
