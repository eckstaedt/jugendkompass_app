import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

/// Primary Button Widget - Standard CTA Button
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? height;
  final EdgeInsets? padding;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? DesignTokens.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8),
                      ),
                ),
              )
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
          ),
        ),
      ),
    );
  }
}

/// Secondary Button Widget
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double? height;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? DesignTokens.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.primaryRed,
          side: const BorderSide(
            color: DesignTokens.primaryRed,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
          ),
        ),
      ),
    );
  }
}

/// Floating Action Button
class FloatingActionButtonCustom extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;

  const FloatingActionButtonCustom({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: DesignTokens.primaryRed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFloatingButton),
      ),
      elevation: 0,
      child: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

/// Rounded Card Widget - Große, weiche Cards
class RoundedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool withShadow;
  /// if true, renders the card with a "liquid glass" effect using a
  /// blurred backdrop and semi-translucent background colour.
  final bool glass;

  const RoundedCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.withShadow = true,
    this.glass = false,
  });

  @override
  _RoundedCardState createState() => _RoundedCardState();
}

class _RoundedCardState extends State<RoundedCard> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final scale = _pressed ? 0.97 : 1.0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
              boxShadow: widget.withShadow ? [DesignTokens.shadowLargeCard] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
              child: widget.glass
                  ? BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: DesignTokens.glassBlurSigma,
                          sigmaY: DesignTokens.glassBlurSigma),
                      child: Padding(
                        padding: widget.padding ?? const EdgeInsets.all(DesignTokens.spacingMedium),
                        child: widget.child,
                      ),
                    )
                  : Padding(
                      padding: widget.padding ?? const EdgeInsets.all(DesignTokens.spacingMedium),
                      child: widget.child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge / Pill Widget
class BadgeWidget extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const BadgeWidget({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? DesignTokens.redBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: textColor ?? DesignTokens.primaryRed,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor ?? DesignTokens.primaryRed,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon Button mit Hintergrund Container
class IconButtonContainer extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final bool withShadow;

  const IconButtonContainer({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: withShadow
              ? [DesignTokens.shadowIconContainer]
              : [],
        ),
        child: Icon(
          icon,
          color: iconColor ?? DesignTokens.iconGrey,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// Divider mit Spacing
class CustomDivider extends StatelessWidget {
  final Color? color;
  final double height;
  final EdgeInsets? padding;

  const CustomDivider({
    super.key,
    this.color,
    this.height = 1,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: DesignTokens.spacingMedium),
      child: Divider(
        color: color ?? Colors.grey.shade200,
        thickness: height,
        height: height + 20,
      ),
    );
  }
}

/// Section Container mit Title
class SectionContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;
  final EdgeInsets? padding;

  const SectionContainer({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.onTrailingTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: DesignTokens.paddingHorizontal,
        vertical: DesignTokens.spacingMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailing != null)
                GestureDetector(
                  onTap: onTrailingTap,
                  child: trailing,
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingSmall),
          child,
        ],
      ),
    );
  }
}
