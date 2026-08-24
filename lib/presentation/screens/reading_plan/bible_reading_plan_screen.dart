import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/utils/snackbar_utils.dart';
import 'package:jugendkompass_app/data/models/bible_reading_plan_model.dart';
import 'package:jugendkompass_app/data/services/bible_reading_plan_service.dart';
import 'package:jugendkompass_app/domain/providers/bible_reading_plan_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';

/// "Bibel in 365 Tagen" — a full year Bible reading plan.
///
/// On first open, shows an intro screen ("Die ganze Bibel in einem Jahr")
/// with a "Bibelleseplan starten 🚀" button. Only after starting does the
/// actual chapter overview appear, showing the current day by default (with
/// its calendar date), letting the user skip forward/back to any day. Every
/// chapter is listed individually and can be checked off; once every
/// chapter for a day is checked, a green confirmation appears at the bottom.
class BibleReadingPlanScreen extends ConsumerStatefulWidget {
  const BibleReadingPlanScreen({super.key});

  @override
  ConsumerState<BibleReadingPlanScreen> createState() => _BibleReadingPlanScreenState();
}

class _BibleReadingPlanScreenState extends ConsumerState<BibleReadingPlanScreen> {
  int? _viewedDay;

  void _goToDay(int day) {
    if (day < 1 || day > 365) return;
    setState(() => _viewedDay = day);
  }

  @override
  Widget build(BuildContext context) {
    final hasStarted = ref.watch(bibleReadingHasStartedProvider);
    final translate = ref.watch(stringTranslatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Bibel in 365 Tagen')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: hasStarted ? _buildPlanView(context) : _buildIntro(context),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final translate = ref.watch(stringTranslatorProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.paddingHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 72,
              color: DesignTokens.primaryRed,
            ),
            const SizedBox(height: DesignTokens.spacingMedium),
            Text(
              translate('Die ganze Bibel in einem Jahr'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                textStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSmall),
            Text(
              translate('365 Tage, ein Kapitel nach dem anderen – lies die komplette Bibel in einem Jahr.'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLarge),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await ref.read(bibleReadingHasStartedProvider.notifier).start();
                  if (!mounted) return;
                  setState(() {
                    _viewedDay = ref.read(bibleReadingTodayDayNumberProvider);
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                  ),
                ),
                child: Text(
                  '${translate('Bibelleseplan starten')} 🚀',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final translate = ref.watch(stringTranslatorProvider);
    final plan = ref.watch(bibleReadingPlanProvider);
    final todayDay = ref.watch(bibleReadingTodayDayNumberProvider);
    final checkedState = ref.watch(bibleReadingCheckedProvider);
    final checkedNotifier = ref.read(bibleReadingCheckedProvider.notifier);

    final viewedDay = _viewedDay ?? todayDay;
    final day = plan.firstWhere((d) => d.dayNumber == viewedDay);
    final checkedIndices = checkedState[day.dayNumber] ?? const <int>{};
    final isDayCompleted = checkedIndices.length >= day.chapters.length;
    final completedDaysCount = checkedNotifier.completedDaysCount(plan);
    final isToday = viewedDay == todayDay;
    final dayDate = BibleReadingPlanService.instance.getDateForDay(day.dayNumber);
    final dateFormat = DateFormat('EEEE, dd. MMMM yyyy', 'de_DE');

    return Column(
      children: [
        // Overall progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.paddingHorizontal,
            DesignTokens.spacingSmall,
            DesignTokens.paddingHorizontal,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
                child: LinearProgressIndicator(
                  value: completedDaysCount / 365,
                  minHeight: 8,
                  backgroundColor:
                      isDark ? DesignTokens.darkCardBackground : DesignTokens.redBackground,
                  valueColor: const AlwaysStoppedAnimation(DesignTokens.primaryRed),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$completedDaysCount / 365 ${translate('Tage abgeschlossen')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spacingMedium),

        // Day navigator: skip back / forward
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.paddingHorizontal),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: viewedDay > 1 ? () => _goToDay(viewedDay - 1) : null,
                icon: const Icon(Icons.chevron_left, size: 32),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${translate('Tag')} ${day.dayNumber}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        textStyle: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        dateFormat.format(dayDate),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary,
                        ),
                      ),
                    ),
                    if (isToday)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          translate('Heute'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: DesignTokens.primaryRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: TextButton(
                          onPressed: () => _goToDay(todayDay),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            translate('Zu heute springen'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: DesignTokens.primaryRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: viewedDay < 365 ? () => _goToDay(viewedDay + 1) : null,
                icon: const Icon(Icons.chevron_right, size: 32),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spacingMedium),

        // Reading list for the viewed day — one row per chapter
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.paddingHorizontal,
              0,
              DesignTokens.paddingHorizontal,
              DesignTokens.spacingLarge,
            ),
            itemCount: day.chapters.length,
            itemBuilder: (context, index) {
              final chapter = day.chapters[index];
              final isChecked = checkedIndices.contains(index);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ChapterTile(
                  chapter: chapter,
                  isChecked: isChecked,
                  isDark: isDark,
                  onTap: () async {
                    final nowChecked = await checkedNotifier.toggle(day.dayNumber, index);
                    if (!context.mounted) return;

                    final allChecked = day.chapters.asMap().entries.every(
                          (entry) => entry.key == index
                              ? nowChecked
                              : (ref.read(bibleReadingCheckedProvider)[day.dayNumber] ?? const <int>{})
                                  .contains(entry.key),
                        );

                    if (nowChecked && allChecked) {
                      SnackBarUtils.showSuccessBottom(
                        context,
                        '${translate('Du hast Tag')} ${day.dayNumber} ${translate('abgeschlossen')}! 🎉',
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),

        // Completion banner for already-completed days
        if (isDayCompleted)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              DesignTokens.paddingHorizontal,
              0,
              DesignTokens.paddingHorizontal,
              DesignTokens.spacingMedium,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: (isDark ? DesignTokens.darkSuccessColor : DesignTokens.successColor)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: isDark ? DesignTokens.darkSuccessColor : DesignTokens.successColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${translate('Du hast Tag')} ${day.dayNumber} ${translate('abgeschlossen')}!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? DesignTokens.darkSuccessColor : DesignTokens.successColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final BibleReadingChapter chapter;
  final bool isChecked;
  final bool isDark;
  final VoidCallback onTap;

  const _ChapterTile({
    required this.chapter,
    required this.isChecked,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isDark ? DesignTokens.darkCardBackground : DesignTokens.cardBackground,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked ? DesignTokens.successColor : Colors.transparent,
                  border: Border.all(
                    color: isChecked
                        ? DesignTokens.successColor
                        : (isDark ? DesignTokens.darkIconGrey : DesignTokens.iconGrey),
                    width: 2,
                  ),
                ),
                child: isChecked
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  chapter.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                    color: isChecked
                        ? (isDark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
