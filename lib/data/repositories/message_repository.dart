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

  /// Fetch a single message by ID
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
}
