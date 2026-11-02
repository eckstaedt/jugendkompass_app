import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/category_model.dart';
import 'package:jugendkompass_app/data/services/content_localizer.dart';

class CategoryRepository {
  final SupabaseClient _supabase;

  CategoryRepository(this._supabase) : _localizer = ContentLocalizer.forClient(_supabase);

  final ContentLocalizer _localizer;

  Future<List<Map<String, dynamic>>> _localize(List rows, String language) {
    return _localizer.localizeEntityRows(
      rows.map((json) => Map<String, dynamic>.from(json as Map)).toList(),
      language,
      entityType: 'category',
      fields: const {'name': 'name'},
    );
  }

  /// Fetch all categories from the database
  Future<List<CategoryModel>> getCategories({
    String language = ContentLocalizer.sourceLanguage,
  }) async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id, name')
          .order('name', ascending: true);

      final rows = await _localize(response as List, language);
      return rows.map(CategoryModel.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Fetch a single category by ID
  Future<CategoryModel?> getCategoryById(
    String id, {
    String language = ContentLocalizer.sourceLanguage,
  }) async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id, name')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      final rows = await _localize([response], language);
      return CategoryModel.fromJson(rows.first);
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  /// Fetch a single category by name
  Future<CategoryModel?> getCategoryByName(String name) async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id, name')
          .eq('name', name)
          .maybeSingle();

      if (response == null) return null;

      return CategoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }
}
