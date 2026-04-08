import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/content_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/presentation/screens/content/content_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/content/widgets/content_card.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/widgets/common/skeleton_loading.dart';

class ContentScreen extends ConsumerStatefulWidget {
  const ContentScreen({super.key});

  @override
  ConsumerState<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends ConsumerState<ContentScreen> {
  String? _selectedCategoryId;
  String? _selectedContentType;

  ContentFilter get _currentFilter => ContentFilter(
        categoryId: _selectedCategoryId,
        contentType: _selectedContentType,
      );

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final translate = ref.watch(stringTranslatorProvider);
    final contentAsync = ref.watch(contentListProvider(_currentFilter));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Inhalte')),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Category Filter
          SizedBox(
            height: 60,
            child: categoriesAsync.when(
              data: (categories) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  FilterChip(
                    label: Text(translate('Alle')),
                    selected: _selectedCategoryId == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.name),
                          selected: _selectedCategoryId == category.id,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = selected ? category.id : null;
                            });
                          },
                        ),
                      )),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),

          // Content Type Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String?>(
              segments: [
                ButtonSegment(
                  value: null,
                  label: Text(translate('Alle')),
                  icon: const Icon(Icons.grid_view),
                ),
                ButtonSegment(
                  value: 'article',
                  label: Text(translate('Artikel')),
                  icon: const Icon(Icons.article),
                ),
                ButtonSegment(
                  value: 'audio',
                  label: Text(translate('Audio')),
                  icon: const Icon(Icons.headphones),
                ),
                ButtonSegment(
                  value: 'video',
                  label: Text(translate('Video')),
                  icon: const Icon(Icons.play_circle),
                ),
              ],
              selected: {_selectedContentType},
              onSelectionChanged: (Set<String?> newSelection) {
                setState(() {
                  _selectedContentType = newSelection.first;
                });
              },
            ),
          ),

          // Content List
          Expanded(
            child: contentAsync.when(
              data: (contentList) {
                if (contentList.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Keine Inhalte gefunden',
                    message: 'Es sind noch keine Inhalte verfügbar.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(contentListProvider(_currentFilter));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: contentList.length,
                    itemBuilder: (context, index) {
                      final content = contentList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ContentCard(
                          content: content,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ContentDetailScreen(
                                  contentId: content.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const ContentListSkeleton(),
              error: (error, stack) => ErrorView(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(contentListProvider(_currentFilter));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
