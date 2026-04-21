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

  /// Get localized impulses using Supabase RPC function.
  ///
  /// Uses get_impulses_localized(lang) which returns impulses with
  /// translated title and impulse_text fields. German (de) returns original.
  Future<List<ImpulseModel>> getImpulsesLocalized(
    String language, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_impulses_localized',
        params: {'lang': language},
      );

      final impulses = (response as List)
          .map((json) => ImpulseModel.fromJson(json))
          .toList();

      // Apply limit and offset client-side
      return impulses.skip(offset).take(limit).toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der lokalisierten Impulse: $e');
    }
  }

  /// Get a single localized impulse by ID.
  Future<ImpulseModel?> getImpulseByIdLocalized(String id, String language) async {
    try {
      // For German, use regular method
      if (language == 'de') {
        return getImpulseById(id);
      }

      // Get impulse
      final impulse = await getImpulseById(id);
      if (impulse == null) return null;

      // If no content_id, return as-is
      if (impulse.contentId == null) return impulse;

      // Fetch translations
      final translations = await _supabase
          .from('content_translations')
          .select('field_name, value')
          .eq('content_id', impulse.contentId!)
          .eq('language', language);

      String? translatedTitle;
      String? translatedText;

      for (final row in translations as List) {
        final field = row['field_name'] as String;
        final value = row['value'] as String;

        if (field == 'title') translatedTitle = value;
        if (field == 'impulse_text') translatedText = value;
      }

      // Return impulse with translations
      return ImpulseModel(
        id: impulse.id,
        contentId: impulse.contentId,
        title: translatedTitle ?? impulse.title,
        date: impulse.date,
        impulseText: translatedText ?? impulse.impulseText,
        imageUrl: impulse.imageUrl,
        createdAt: impulse.createdAt,
        status: impulse.status,
      );
    } catch (e) {
      throw Exception('Fehler beim Laden des lokalisierten Impulses: $e');
    }
  }
}
