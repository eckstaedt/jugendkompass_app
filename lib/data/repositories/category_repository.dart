import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/category_model.dart';

class CategoryRepository {
  final SupabaseClient _supabase;

  CategoryRepository(this._supabase);

  /// Fetch all categories from the database
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id, name')
          .order('name', ascending: true);

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Fetch a single category by ID
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id, name')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return CategoryModel.fromJson(response);
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
