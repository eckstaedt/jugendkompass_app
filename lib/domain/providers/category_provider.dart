import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/category_model.dart';
import 'package:jugendkompass_app/data/repositories/category_repository.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

/// Provider for CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return CategoryRepository(supabase);
});

/// Provider for fetching all categories
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategories();
});

/// Provider for fetching a single category by ID
final categoryByIdProvider = FutureProvider.family<CategoryModel?, String>((ref, id) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryById(id);
});

/// Provider for fetching a single category by name
final categoryByNameProvider = FutureProvider.family<CategoryModel?, String>((ref, name) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryByName(name);
});
