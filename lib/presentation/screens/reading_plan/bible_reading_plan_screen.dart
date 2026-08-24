import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/utils/snackbar_utils.dart';
import 'package:jugendkompass_app/data/models/bible_reading_plan_model.dart';
import 'package:jugendkompass_app/domain/providers/bible_reading_plan_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';

/// "Bibel in 365 Tagen" — a full year Bible reading plan.
///
/// Shows the current day by default (based on when the user started the
/// plan), but lets the user skip forward/back to any day. Each day lists
/// the chapters to read; checking off every reading for a day marks that
/// day as completed and shows a green confirmation at the bottom.
class BibleReadingPlanScreen extends ConsumerStatefulWidget {
  const BibleReadingPlanScreen({super.key});

  @override
  ConsumerState<BibleReadingPlanScreen> createState() => _BibleReadingPlanScreenState();
}

class _BibleReadingPlanScreenState extends ConsumerState<BibleReadingPlanScreen> {
  late int _viewedDay;

  @override
  void initState() {
    super.initState();
    _viewedDay = ref.read(bibleReadingTodayDayNumberProvider);
  }

  void _goToDay(int day) {
    if (day < 1 || day > 365) return;
    setState(() => _viewedDay = day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final translate = ref.watch(stringTranslatorProvider);
    final plan = ref.watch(bibleReadingPlanProvider);
    final todayDay = ref.watch(bibleReadingTodayDayNumberProvider);
    final checkedState = ref.watch(bibleReadingCheckedProvider);
    final checkedNotifier = ref.read(bibleReadingCheckedProvider.notifier);

    final day = plan.firstWhere((d) => d.dayNumber == _viewedDay);
    final checkedIndices = checkedState[day.dayNumber] ?? const <int>{};
    final isDayCompleted = checkedIndices.length >= day.readings.length;
    final completedDaysCount = checkedNotifier.completedDaysCount(plan);
    final isToday = _viewedDay == todayDay;

    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkAppBackground : DesignTokens.appBackground,
      appBar: AppBar(
        title: Text(translate('Bibel in 365 Tagen')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
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
                    onPressed: _viewedDay > 1 ? () => _goToDay(_viewedDay - 1) : null,
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
                    onPressed: _viewedDay < 365 ? () => _goToDay(_viewedDay + 1) : null,
                    icon: const Icon(Icons.chevron_right, size: 32),
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.spacingMedium),

            // Reading list for the viewed day
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.paddingHorizontal,
                  0,
                  DesignTokens.paddingHorizontal,
                  DesignTokens.spacingLarge,
                ),
                itemCount: day.readings.length,
                itemBuilder: (context, index) {
                  final reading = day.readings[index];
                  final isChecked = checkedIndices.contains(index);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReadingTile(
                      reading: reading,
                      isChecked: isChecked,
                      isDark: isDark,
                      onTap: () async {
                        final nowChecked = await checkedNotifier.toggle(day.dayNumber, index);
                        if (!context.mounted) return;

                        final allChecked = day.readings.asMap().entries.every(
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
        ),
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final BibleReadingRange reading;
  final bool isChecked;
  final bool isDark;
  final VoidCallback onTap;

  const _ReadingTile({
    required this.reading,
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
                  reading.label,
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
