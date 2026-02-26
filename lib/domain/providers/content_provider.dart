import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/content_model.dart';
import 'package:jugendkompass_app/data/models/category_model.dart';
import 'package:jugendkompass_app/data/repositories/content_repository.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ContentRepository(supabase);
});

final contentListProvider = FutureProvider.family<List<ContentModel>, ContentFilter>(
  (ref, filter) async {
    final repository = ref.watch(contentRepositoryProvider);
    return await repository.getContentList(
      categoryId: filter.categoryId,
      contentType: filter.contentType,
    );
  },
);

final contentDetailProvider = FutureProvider.family<ContentModel?, String>(
  (ref, contentId) async {
    final repository = ref.watch(contentRepositoryProvider);
    return await repository.getContentById(contentId);
  },
);

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repository = ref.watch(contentRepositoryProvider);
  return await repository.getCategories();
});

class ContentFilter {
  final String? categoryId;
  final String? contentType;

  ContentFilter({
    this.categoryId,
    this.contentType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentFilter &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          contentType == other.contentType;

  @override
  int get hashCode => categoryId.hashCode ^ contentType.hashCode;
}
