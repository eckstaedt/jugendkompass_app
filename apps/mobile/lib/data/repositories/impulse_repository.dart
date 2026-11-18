import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/impulse_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';
import 'dart:developer' as developer;
import 'package:jugendkompass_app/data/services/content_localizer.dart';

class ImpulseRepository {
  final SupabaseClient _supabase;

  ImpulseRepository(this._supabase) : _localizer = ContentLocalizer.forClient(_supabase);

  final ContentLocalizer _localizer;

  /// Overlays translated title and impulse text.
  Future<List<ImpulseModel>> localizeImpulses(List<ImpulseModel> impulses, String language) async {
    if (!ContentLocalizer.needsTranslation(language) || impulses.isEmpty) return impulses;
    final rows = await _localizer.localizeContentRows(
      [
        for (final i in impulses) {'content_id': i.contentId, 'title': i.title, 'impulse_text': i.impulseText},
      ],
      language,
      fields: const {'title': 'title', 'impulse_text': 'impulse_text'},
    );
    return [
      for (var i = 0; i < impulses.length; i++)
        ImpulseModel(
          id: impulses[i].id,
          contentId: impulses[i].contentId,
          title: rows[i]['title'] as String,
          date: impulses[i].date,
          impulseText: rows[i]['impulse_text'] as String,
          imageUrl: impulses[i].imageUrl,
          createdAt: impulses[i].createdAt,
          status: impulses[i].status,
        ),
    ];
  }

  Future<ImpulseModel?> _localizeOne(ImpulseModel? impulse, String language) async {
    if (impulse == null) return null;
    return (await localizeImpulses([impulse], language)).first;
  }

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
      rethrow;
    }
  }

  /// Get a single impulse by its content_id (FK to the polymorphic `content`
  /// table). Used for deep linking from push notifications.
  Future<ImpulseModel?> getImpulseByContentId(String contentId) async {
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
          .eq('content_id', contentId)
          .maybeSingle();

      if (response != null) {
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

  /// Get a localized impulse by content_id.
  Future<ImpulseModel?> getImpulseByContentIdLocalized(String contentId, String language) async {
    try {
      return await _localizeOne(await getImpulseByContentId(contentId), language);
    } catch (e) {
      throw Exception('Fehler beim Laden des lokalisierten Impulses: $e');
    }
  }

  /// Get localized, published impulses up to today (newest first).
  Future<List<ImpulseModel>> getImpulsesLocalized(
    String language, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

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
          .lte('date', today)
          .order('date', ascending: false)
          .range(offset, offset + limit - 1);

      final impulses = (response as List)
          .map((json) => ImpulseModel.fromJson({
                ...Map<String, dynamic>.from(json as Map),
                'status': (json['content'] as Map?)?['status'],
              }))
          .where((impulse) {
            final status = impulse.status?.toLowerCase();
            return status == null || status == 'published';
          })
          .toList();

      return await localizeImpulses(impulses, language);
    } catch (e) {
      throw Exception('Fehler beim Laden der lokalisierten Impulse: $e');
    }
  }

  /// Get a single localized impulse by ID.
  Future<ImpulseModel?> getImpulseByIdLocalized(String id, String language) async {
    try {
      return await _localizeOne(await getImpulseById(id), language);
    } catch (e) {
      throw Exception('Fehler beim Laden des lokalisierten Impulses: $e');
    }
  }
}
