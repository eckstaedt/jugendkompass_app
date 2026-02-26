import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/content_model.dart';
import 'package:jugendkompass_app/data/models/category_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';

class ContentRepository {
  final SupabaseClient _supabase;

  ContentRepository(this._supabase);

  Future<List<ContentModel>> getContentList({
    String? categoryId,
    String? contentType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // JOIN with posts table to get displayable metadata
      dynamic query = _supabase
          .from(SupabaseConstants.contentTable)
          .select('''
            id,
            content_type,
            status,
            created_at,
            posts!content_id(
              title,
              body,
              image_url,
              category_id,
              edition_id,
              audio_id
            )
          ''');

      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }

      // Note: Category filtering needs to be done client-side since
      // category_id is in the joined posts table, not the content table.
      // Alternatively, query from posts table instead.

      query = query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;

      var contentList = (response as List).map((json) {
        // Extract posts data from JOIN result
        final posts = json['posts'];
        final postData = (posts is List && posts.isNotEmpty) ? posts[0] : null;

        return ContentModel.fromJson({
          'id': json['id'],
          'content_type': json['content_type'],
          'status': json['status'],
          'created_at': json['created_at'],
          'title': postData?['title'],
          'body': postData?['body'],
          'image_url': postData?['image_url'],
          'category_id': postData?['category_id'],
          'edition_id': postData?['edition_id'],
          'audio_id': postData?['audio_id'],
        });
      }).toList();

      // Apply category filter client-side if needed
      if (categoryId != null) {
        contentList = contentList
            .where((content) => content.categoryId == categoryId)
            .toList();
      }

      return contentList;
    } catch (e) {
      throw Exception('Fehler beim Laden der Inhalte: $e');
    }
  }

  Future<ContentModel?> getContentById(String id) async {
    try {
      // JOIN with posts table to get displayable metadata
      final response = await _supabase
          .from(SupabaseConstants.contentTable)
          .select('''
            id,
            content_type,
            status,
            created_at,
            posts!content_id(
              title,
              body,
              image_url,
              category_id,
              edition_id,
              audio_id
            )
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        // Extract posts data from JOIN result
        final posts = response['posts'];
        final postData = (posts is List && posts.isNotEmpty) ? posts[0] : null;

        return ContentModel.fromJson({
          'id': response['id'],
          'content_type': response['content_type'],
          'status': response['status'],
          'created_at': response['created_at'],
          'title': postData?['title'],
          'body': postData?['body'],
          'image_url': postData?['image_url'],
          'category_id': postData?['category_id'],
          'edition_id': postData?['edition_id'],
          'audio_id': postData?['audio_id'],
        });
      }
      return null;
    } catch (e) {
      throw Exception('Fehler beim Laden des Inhalts: $e');
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.categoriesTable)
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der Kategorien: $e');
    }
  }
}
