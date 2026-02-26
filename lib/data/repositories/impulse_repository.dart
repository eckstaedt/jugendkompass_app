import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/impulse_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';
import 'dart:developer' as developer;

class ImpulseRepository {
  final SupabaseClient _supabase;

  ImpulseRepository(this._supabase);

  /// Get daily impulses with JOIN to content table for status
  /// Direct fields (title, date, image_url) come from impulses table
  Future<List<ImpulseModel>> getDailyImpulses({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      // Join impulses with content table to get status
      final response = await _supabase
          .from(SupabaseConstants.impulsesTable)
          .select('''
            id,
            content_id,
            title,
            date,
            impulse_text,
            image_url,
            created_at,
            content!content_id(
              status
            )
          ''')
          .order('date', ascending: false)
          .range(offset, offset + limit - 1);

      // Debug logging
      developer.log('Impulses response: ${response.length} items', name: 'ImpulseRepository');
      if (response.isNotEmpty) {
        developer.log('First impulse data: ${response[0]}', name: 'ImpulseRepository');
      }

      final impulses = (response as List)
          .map((json) {
            // Extract nested content data
            final contentData = json['content'];

            // Debug log for each impulse
            developer.log(
              'Impulse: id=${json['id']}, title=${json['title']}, image_url=${json['image_url']}',
              name: 'ImpulseRepository',
            );

            return ImpulseModel.fromJson({
              'id': json['id'],
              'content_id': json['content_id'],
              'title': json['title'],
              'date': json['date'],
              'impulse_text': json['impulse_text'],
              'image_url': json['image_url'],
              'created_at': json['created_at'],
              'status': contentData?['status'],
            });
          })
          .toList();

      // Only filter by status if it's available
      final filteredImpulses = impulses.where((impulse) {
        // If status is null or published, include the impulse
        final status = impulse.status?.toLowerCase();
        return status == null || status == 'published';
      }).toList();

      developer.log(
        'Filtered impulses: ${filteredImpulses.length} out of ${impulses.length}',
        name: 'ImpulseRepository',
      );

      return filteredImpulses;
    } catch (e) {
      throw Exception('Fehler beim Laden der Impulse: $e');
    }
  }

  /// Get a single impulse by ID
  Future<ImpulseModel?> getImpulseById(String id) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.impulsesTable)
          .select('''
            id,
            content_id,
            title,
            date,
            impulse_text,
            image_url,
            created_at,
            content!content_id(
              status
            )
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        // Extract nested content data
        final contentData = response['content'];

        return ImpulseModel.fromJson({
          'id': response['id'],
          'content_id': response['content_id'],
          'title': response['title'],
          'date': response['date'],
          'impulse_text': response['impulse_text'],
          'image_url': response['image_url'],
          'created_at': response['created_at'],
          'status': contentData?['status'],
        });
      }
      return null;
    } catch (e) {
      throw Exception('Fehler beim Laden des Impulses: $e');
    }
  }
}
