import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/utils/html_utils.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';

/// Long-press preview of a post / impulse / message: blurred background,
/// image, title, the first lines and an "open" button. Light haptic tick.
Future<void> showContentPreview(
  BuildContext context, {
  required String title,
  String? imageUrl,
  String? text,
  VoidCallback? onOpen,
}) {
  HapticFeedback.mediumImpact();
  final brightness = Theme.of(context).brightness;
  final excerpt = HtmlUtils.stripHtml(text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'preview',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.sizeOf(ctx).width * 0.86,
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.75),
            decoration: BoxDecoration(
              color: DesignTokens.getCardBackground(brightness),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
              boxShadow: [DesignTokens.shadowLargeCard],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    AspectRatio(aspectRatio: 16 / 10, child: CorsNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Text(HtmlUtils.stripHtml(title),
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (excerpt.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(excerpt, maxLines: 6, overflow: TextOverflow.ellipsis,
                          style: TextStyle(height: 1.45, color: DesignTokens.getTextSecondary(brightness))),
                    ),
                  if (onOpen != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: DesignTokens.primaryRed),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onOpen();
                        },
                        child: Text(AppTranslations.t('open_preview')),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, a, __, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: child),
    ),
  );
}
