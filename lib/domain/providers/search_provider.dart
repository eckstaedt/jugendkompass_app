import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/content_model.dart';
import 'package:jugendkompass_app/data/models/impulse_model.dart';
import 'package:jugendkompass_app/domain/providers/content_provider.dart';
import 'package:jugendkompass_app/domain/providers/impulse_provider.dart';

/// Combined search results
class SearchResult {
  final List<ContentModel> contents;
  final List<ImpulseModel> impulses;

  SearchResult({
    required this.contents,
    required this.impulses,
  });

  bool get isEmpty => contents.isEmpty && impulses.isEmpty;

  int get totalCount => contents.length + impulses.length;
}

/// Search provider that searches across all content types
final searchProvider = FutureProvider.family<SearchResult, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return SearchResult(contents: [], impulses: []);
  }

  final searchQuery = query.toLowerCase().trim();

  try {
    // Get all contents (articles, videos, audios)
    final allContents = await ref.read(contentRepositoryProvider).getContentList(limit: 100);

    // Get all impulses
    final allImpulses = await ref.read(impulseRepositoryProvider).getDailyImpulses(limit: 100);

    // Filter contents by search query (search in title and body)
    final filteredContents = allContents.where((content) {
      final matchesTitle = content.title?.toLowerCase().contains(searchQuery) ?? false;
      final matchesBody = content.body?.toLowerCase().contains(searchQuery) ?? false;
      final isPublished = content.isPublished;

      return (matchesTitle || matchesBody) && isPublished;
    }).toList();

    // Filter impulses by search query (search in title and impulse_text)
    final filteredImpulses = allImpulses.where((impulse) {
      final matchesTitle = impulse.displayTitle.toLowerCase().contains(searchQuery);
      final matchesBody = impulse.impulseText.toLowerCase().contains(searchQuery);
      final isPublished = impulse.status?.toLowerCase() == 'published' || impulse.status == null;

      return (matchesTitle || matchesBody) && isPublished;
    }).toList();

    return SearchResult(
      contents: filteredContents,
      impulses: filteredImpulses,
    );
  } catch (e) {
    throw Exception('Fehler bei der Suche: $e');
  }
});
