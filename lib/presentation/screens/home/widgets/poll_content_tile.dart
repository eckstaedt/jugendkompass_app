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

class _PollContentTileState extends ConsumerState<PollContentTile> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  String? _selectedOptionId;
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
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
    final displayOptions = _isExpanded ? currentPoll.options : currentPoll.options.take(5).toList();

    return GestureDetector(
      onTap: _toggleExpanded,
      child: ClipRRect(
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: brightness == Brightness.dark
                    ? [
                        DesignTokens.getGlassBackground(brightness, 0.3),
                        DesignTokens.getGlassBackground(brightness, 0.22),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.85),
                      ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
              border: Border.all(
                color: brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.18)
                    : DesignTokens.primaryRed.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.primaryRed.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                DesignTokens.shadowGlass,
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with badge and voted status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.primaryRed,
                            DesignTokens.primaryRed.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.primaryRed.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.poll_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('poll_badge'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (hasVoted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: DesignTokens.getSuccessColor(brightness),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('voted'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: DesignTokens.getSuccessColor(brightness),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isExpanded && !hasVoted)
                      RotationTransition(
                        turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: DesignTokens.getTextSecondary(brightness),
                          size: 24,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Poll question
                Text(
                  widget.poll.question,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.getTextPrimary(brightness),
                    height: 1.4,
                    letterSpacing: -0.3,
                  ),
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Poll options
                ...displayOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final percentage = hasVoted ? option.getPercentage(currentPoll.totalVotes) : 0.0;
                  final isUserVote = userVotedOptionId == option.id;
                  final isSelected = _selectedOptionId == option.id;

                  return Padding(
                    padding: EdgeInsets.only(bottom: index < displayOptions.length - 1 ? 10 : 0),
                    child: GestureDetector(
                      // Only allow selection if user hasn't voted yet
                      onTap: hasVoted ? null : () {
                        setState(() {
                          _selectedOptionId = option.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: hasVoted
                              ? (isUserVote
                                  ? LinearGradient(
                                      colors: [
                                        DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.2),
                                        DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.15),
                                      ],
                                    )
                                  : null)
                              : (isSelected
                                  ? LinearGradient(
                                      colors: [
                                        DesignTokens.primaryRed.withValues(alpha: 0.15),
                                        DesignTokens.primaryRed.withValues(alpha: 0.1),
                                      ],
                                    )
                                  : null),
                          color: hasVoted
                              ? (isUserVote ? null : DesignTokens.getCardBackground(brightness).withValues(alpha: 0.4))
                              : (isSelected ? null : DesignTokens.getCardBackground(brightness).withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: hasVoted
                                ? (isUserVote
                                    ? DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.6)
                                    : brightness == Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.08))
                                : (isSelected
                                    ? DesignTokens.primaryRed.withValues(alpha: 0.7)
                                    : brightness == Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.08)),
                            width: isSelected || isUserVote ? 2 : 1,
                          ),
                          boxShadow: isSelected || isUserVote
                              ? [
                                  BoxShadow(
                                    color: (isUserVote
                                            ? DesignTokens.getSuccessColor(brightness)
                                            : DesignTokens.primaryRed)
                                        .withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            // Animated progress bar background for voted polls
                            if (hasVoted)
                              Positioned.fill(
                                child: AnimatedFractionallySizedBox(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  alignment: Alignment.centerLeft,
                                  widthFactor: percentage / 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isUserVote
                                            ? [
                                                DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.3),
                                                DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.15),
                                              ]
                                            : [
                                                DesignTokens.getTextSecondary(brightness).withValues(alpha: 0.15),
                                                DesignTokens.getTextSecondary(brightness).withValues(alpha: 0.08),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
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
                                    width: 22,
                                    height: 22,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? DesignTokens.primaryRed
                                            : DesignTokens.getTextSecondary(brightness),
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? DesignTokens.primaryRed.withValues(alpha: 0.1)
                                          : Colors.transparent,
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
                                      fontSize: 15,
                                      fontWeight: isUserVote ? FontWeight.w700 : FontWeight.w600,
                                      color: DesignTokens.getTextPrimary(brightness),
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasVoted) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                                    decoration: BoxDecoration(
                                      color: isUserVote
                                          ? DesignTokens.getSuccessColor(brightness).withValues(alpha: 0.2)
                                          : DesignTokens.getTextSecondary(brightness).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isUserVote
                                            ? DesignTokens.getSuccessColor(brightness)
                                            : DesignTokens.getTextSecondary(brightness),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Show "more options" if collapsed and there are more than 5
                if (!_isExpanded && currentPoll.options.length > 5) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DesignTokens.primaryRed.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.unfold_more,
                          size: 16,
                          color: DesignTokens.primaryRed,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+${currentPoll.options.length - 5} ${context.tr('more_options')}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.primaryRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Vote button - only show when user hasn't voted and has selected an option
                if (!hasVoted && _selectedOptionId != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            DesignTokens.primaryRed,
                            Color(0xFFD32F2F),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.primaryRed.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitVote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.how_to_vote_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.tr('vote'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Total votes with icon
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: DesignTokens.getTextSecondary(brightness),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${currentPoll.totalVotes} ${context.tr('votes')}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.getTextSecondary(brightness),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
