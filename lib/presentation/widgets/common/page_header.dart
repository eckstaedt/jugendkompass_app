import 'package:flutter/material.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

/// Large, left-aligned page title used by every main tab (Kiosk, Podcast,
/// Videos, Menu) so all pages share the same header.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = defaultPadding,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsets padding;

  static const EdgeInsets defaultPadding = EdgeInsets.fromLTRB(
    DesignTokens.paddingHorizontal,
    24,
    DesignTokens.paddingHorizontal,
    16,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: DesignTokens.getTextPrimary(theme.brightness),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
