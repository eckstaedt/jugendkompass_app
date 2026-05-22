import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/poll_model.dart';
import 'package:jugendkompass_app/domain/providers/poll_provider.dart';
import 'package:jugendkompass_app/domain/providers/read_history_provider.dart';
import 'package:jugendkompass_app/data/models/read_history_item_model.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/utils/snackbar_utils.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

class PollDetailScreen extends ConsumerStatefulWidget {
  final PollModel poll;

  const PollDetailScreen({
    super.key,
    required this.poll,
  });

  @override
  ConsumerState<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends ConsumerState<PollDetailScreen> {
  String? _selectedOptionId;

  @override
  void initState() {
    super.initState();
    // Mark poll as read when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readHistoryProvider.notifier).markAsRead(
        widget.poll.id,
        ReadContentType.poll,
        title: widget.poll.question,
      );
    });
  }

  Future<void> _submitVote() async {
    if (_selectedOptionId == null) return;

    try {
      await ref.read(pollVoteNotifierProvider.notifier).submitVote(
        widget.poll.id,
        _selectedOptionId!,
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, context.tr('voted'));
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          e.toString().contains('bereits') || e.toString().contains('already')
              ? context.tr('already_voted')
              : context.tr('poll_vote_error'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final supabase = ref.watch(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;

    // Watch the poll to get updated data
    final pollAsync = ref.watch(pollByIdProvider(widget.poll.id));

    // Check if user has voted
    final userVoteAsync = ref.watch(userVoteProvider(widget.poll.id));
    final hasVoted = userVoteAsync.value != null;
    final votedOptionId = userVoteAsync.value?.optionId;

    // Watch vote submission state
    final voteState = ref.watch(pollVoteNotifierProvider);
    final isSubmitting = voteState.isLoading;

    final currentPoll = pollAsync.value ?? widget.poll;

    return Scaffold(
      backgroundColor: DesignTokens.getAppBackground(brightness),
      appBar: AppBar(
        title: Text(context.tr('poll_badge')),
        backgroundColor: DesignTokens.getCardBackground(brightness),
        elevation: 0,
      ),
      body: pollAsync.when(
        data: (poll) {
          if (poll == null) {
            return Center(
              child: Text(
                context.tr('poll_error'),
                style: TextStyle(
                  color: DesignTokens.getTextSecondary(brightness),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: DesignTokens.overlayPaddingBase + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poll question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: DesignTokens.getCardBackground(brightness),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
                    border: DesignTokens.cardBorder(brightness),
                    boxShadow: [DesignTokens.shadowLargeCard],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poll.question,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.getTextPrimary(brightness),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.how_to_vote_rounded,
                            size: 18,
                            color: DesignTokens.getTextSecondary(brightness),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${poll.totalVotes} ${context.tr('votes')}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: DesignTokens.getTextSecondary(brightness),
                            ),
                          ),
                          if (hasVoted) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                context.tr('voted'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DesignTokens.getSuccessColor(brightness),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Options list
                ...poll.options.map((option) {
                  final isSelected = _selectedOptionId == option.id;
                  final isVoted = votedOptionId == option.id;
                  final percentage = hasVoted ? option.getPercentage(poll.totalVotes) : 0.0;

                  return GestureDetector(
                    onTap: hasVoted
                        ? null
                        : () {
                            setState(() {
                              _selectedOptionId = option.id;
                            });
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: DesignTokens.glassBlurSigma,
                            sigmaY: DesignTokens.glassBlurSigma,
                          ),
                          child: Stack(
                            children: [
                              // Background progress bar (only show if voted)
                              if (hasVoted)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  width: MediaQuery.of(context).size.width * (percentage / 100),
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        DesignTokens.getPollBadgeColor(brightness).withValues(alpha: 0.3),
                                        DesignTokens.getPollBadgeColor(brightness).withValues(alpha: 0.1),
                                      ],
                                    ),
                                  ),
                                ),

                              // Option content
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? DesignTokens.getPollBadgeColor(brightness).withValues(alpha: 0.15)
                                      : DesignTokens.getGlassBackground(brightness, 0.12),
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
                                  border: Border.all(
                                    color: isSelected || isVoted
                                        ? DesignTokens.getPollBadgeColor(brightness)
                                        : (brightness == Brightness.dark
                                            ? Colors.white.withValues(alpha: 0.15)
                                            : Colors.black.withValues(alpha: 0.10)),
                                    width: isSelected || isVoted ? 2 : 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Radio/Check indicator
                                    if (!hasVoted)
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? DesignTokens.getPollBadgeColor(brightness)
                                                : DesignTokens.getTextSecondary(brightness),
                                            width: 2,
                                          ),
                                          color: isSelected
                                              ? DesignTokens.getPollBadgeColor(brightness)
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      )
                                    else
                                      Icon(
                                        isVoted ? Icons.check_circle : Icons.circle_outlined,
                                        size: 24,
                                        color: isVoted
                                            ? DesignTokens.getSuccessColor(brightness)
                                            : DesignTokens.getTextSecondary(brightness),
                                      ),

                                    const SizedBox(width: 16),

                                    // Option text
                                    Expanded(
                                      child: Text(
                                        option.optionText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: DesignTokens.getTextPrimary(brightness),
                                        ),
                                      ),
                                    ),

                                    // Percentage and votes (only show if voted)
                                    if (hasVoted) ...[
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${percentage.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: DesignTokens.getTextPrimary(brightness),
                                            ),
                                          ),
                                          Text(
                                            '${option.votes} ${context.tr('votes')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: DesignTokens.getTextSecondary(brightness),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),

                // Vote button (only show if not voted yet)
                if (!hasVoted && userId != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: DesignTokens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _selectedOptionId == null || isSubmitting ? null : _submitVote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryRed,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: DesignTokens.getTextSecondary(brightness),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              context.tr('vote'),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],

                // Login prompt if not signed in
                if (userId == null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignTokens.getCardBackground(brightness),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
                      border: DesignTokens.cardBorder(brightness),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: DesignTokens.getTextSecondary(brightness),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bitte melde dich an, um abzustimmen',
                            style: TextStyle(
                              fontSize: 14,
                              color: DesignTokens.getTextSecondary(brightness),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: DesignTokens.primaryRed,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            context.tr('poll_error'),
            style: TextStyle(
              color: DesignTokens.getTextSecondary(brightness),
            ),
          ),
        ),
      ),
    );
  }
}
