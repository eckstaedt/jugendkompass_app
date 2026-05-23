import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/poll_model.dart';
import 'package:jugendkompass_app/domain/providers/poll_provider.dart';
import 'package:jugendkompass_app/domain/providers/read_history_provider.dart';
import 'package:jugendkompass_app/data/models/read_history_item_model.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

class PollContentTile extends ConsumerStatefulWidget {
  final PollModel poll;

  const PollContentTile({
    super.key,
    required this.poll,
  });

  @override
  ConsumerState<PollContentTile> createState() => _PollContentTileState();
}

class _PollContentTileState extends ConsumerState<PollContentTile> {
  bool _isExpanded = false;
  String? _selectedOptionId;
  bool _isSubmitting = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    // Mark poll as read when first expanded
    if (_isExpanded) {
      ref.read(readHistoryProvider.notifier).markAsRead(
        widget.poll.id,
        ReadContentType.poll,
        title: widget.poll.question,
      );
    }
  }

  Future<void> _submitVote() async {
    if (_selectedOptionId == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(pollVoteNotifierProvider.notifier).submitVote(
        widget.poll.id,
        _selectedOptionId!,
      );

      // Refresh poll data to show updated counts
      ref.invalidate(pollByIdProvider(widget.poll.id));
      ref.invalidate(userVoteProvider(widget.poll.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('vote_submitted_success')),
            backgroundColor: DesignTokens.getSuccessColor(Theme.of(context).brightness),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              left: 16,
              right: 16,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show specific error message if already voted
        final errorMessage = e.toString().contains('bereits')
            ? context.tr('already_voted')
            : context.tr('poll_vote_error');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              left: 16,
              right: 16,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedOptionId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Fetch the latest poll data to get updated vote counts
    final pollAsync = ref.watch(pollByIdProvider(widget.poll.id));
    final currentPoll = pollAsync.value ?? widget.poll;

    // Check if user has voted
    final userVoteAsync = ref.watch(userVoteProvider(widget.poll.id));
    final hasVoted = userVoteAsync.value != null;
    final userVotedOptionId = userVoteAsync.value?.optionId;

    // Determine which options to show
    final displayOptions = _isExpanded ? currentPoll.options : currentPoll.options.take(2).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DesignTokens.glassBlurSigma,
          sigmaY: DesignTokens.glassBlurSigma,
        ),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: DesignTokens.getGlassBackground(brightness, 0.26),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
            border: DesignTokens.cardBorder(brightness),
            boxShadow: [DesignTokens.shadowGlass],
          ),
          padding: const EdgeInsets.all(DesignTokens.spacingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with badge and voted status
              GestureDetector(
                onTap: _toggleExpanded,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    BadgeWidget(
                      label: context.tr('poll_badge'),
                      backgroundColor: brightness == Brightness.dark ? DesignTokens.primaryRed : null,
                      textColor: brightness == Brightness.dark ? Colors.white : null,
                    ),
                    const Spacer(),
                    if (hasVoted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.getSuccessColor(brightness),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Poll question
              GestureDetector(
                onTap: _toggleExpanded,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  widget.poll.question,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.getTextPrimary(brightness),
                    height: 1.3,
                  ),
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),

              // Poll options
              ...displayOptions.map((option) {
                final percentage = hasVoted ? option.getPercentage(currentPoll.totalVotes) : 0.0;
                final isUserVote = userVotedOptionId == option.id;
                final isSelected = _selectedOptionId == option.id;

                return GestureDetector(
                  // Only allow selection if user hasn't voted yet
                  onTap: hasVoted ? null : () {
                    setState(() {
                      _selectedOptionId = option.id;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: hasVoted
                          ? (isUserVote
                              ? DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.15)
                              : DesignTokens.getCardBackground(brightness).withValues(alpha: 0.5))
                          : (isSelected
                              ? DesignTokens.primaryRed.withValues(alpha: 0.15)
                              : DesignTokens.getCardBackground(brightness).withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasVoted
                            ? (isUserVote
                                ? DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.4)
                                : brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08))
                            : (isSelected
                                ? DesignTokens.primaryRed.withValues(alpha: 0.6)
                                : brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08)),
                        width: isSelected || isUserVote ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated progress bar background for voted polls
                        if (hasVoted)
                          Positioned.fill(
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percentage / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isUserVote
                                      ? DesignTokens.getSuccessColor(brightness)
                                      : DesignTokens.getTextSecondary(brightness).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        // Content row
                        Row(
                          children: [
                            // Show radio button only if user hasn't voted yet
                            if (!hasVoted)
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? DesignTokens.primaryRed
                                        : DesignTokens.getTextSecondary(brightness),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: DesignTokens.primaryRed,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            Expanded(
                              child: Text(
                                option.optionText,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isUserVote ? FontWeight.w700 : FontWeight.w500,
                                  color: DesignTokens.getTextPrimary(brightness),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasVoted) ...[
                              const SizedBox(width: 12),
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isUserVote
                                      ? DesignTokens.getSuccessColor(brightness)
                                      : DesignTokens.getTextSecondary(brightness),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Show "more options" if collapsed and there are more than 2
              if (!_isExpanded && currentPoll.options.length > 2) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _toggleExpanded,
                  child: Text(
                    '+${currentPoll.options.length - 2} ${context.tr('more_options')}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: DesignTokens.primaryRed,
                    ),
                  ),
                ),
              ],

              // Vote button - only show when user hasn't voted and has selected an option
              if (!hasVoted && _selectedOptionId != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitVote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            context.tr('vote'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Total votes
              Text(
                '${currentPoll.totalVotes} ${context.tr('votes')}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.getTextSecondary(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
