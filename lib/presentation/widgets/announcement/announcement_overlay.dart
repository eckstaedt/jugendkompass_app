import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/data/models/app_announcement_model.dart';
import 'package:jugendkompass_app/data/repositories/announcement_repository.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';

/// Wraps the whole app (inside `MaterialApp.builder`) and shows the currently
/// active remote announcement (Supabase table `app_announcements`) as a
/// full-screen overlay on app start and whenever the app returns to the
/// foreground.
class AnnouncementOverlay extends ConsumerStatefulWidget {
  const AnnouncementOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AnnouncementOverlay> createState() =>
      _AnnouncementOverlayState();
}

class _AnnouncementOverlayState extends ConsumerState<AnnouncementOverlay>
    with WidgetsBindingObserver {
  final _repository = AnnouncementRepository();
  AppAnnouncement? _announcement;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_checking || _announcement != null) return;
    _checking = true;
    try {
      final a = await _repository.fetchAnnouncementToShow();
      if (!mounted || a == null) return;
      if (a.imageUrl != null && !a.imageUrl!.startsWith('asset:')) {
        // Warm the cache so the image appears together with the text.
        try {
          await precacheImage(NetworkImage(a.imageUrl!), context);
        } catch (_) {}
        if (!mounted) return;
      }
      setState(() => _announcement = a);
    } finally {
      _checking = false;
    }
  }

  Future<void> _dismiss() async {
    final a = _announcement;
    if (a == null) return;
    setState(() => _announcement = null);
    if (a.showOnce) await _repository.markDismissed(a.id);
  }

  @override
  Widget build(BuildContext context) {
    final a = _announcement;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: a == null
                ? const SizedBox.shrink()
                : _AnnouncementView(
                    key: ValueKey(a.id),
                    announcement: a,
                    languageCode:
                        ref.watch(languageProvider).locale.languageCode,
                    onClose: a.dismissible ? _dismiss : null,
                  ),
          ),
        ),
      ],
    );
  }
}

class _AnnouncementView extends StatelessWidget {
  const _AnnouncementView({
    super.key,
    required this.announcement,
    required this.languageCode,
    required this.onClose,
  });

  final AppAnnouncement announcement;
  final String languageCode;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final imageUrl = announcement.imageUrl;

    Widget? image;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      image = imageUrl.startsWith('asset:')
          ? Image.asset(imageUrl.substring('asset:'.length), fit: BoxFit.cover)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            );
    }

    return Material(
      color: DesignTokens.getAppBackground(brightness),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.radiusMiddleContainers),
                          child: AspectRatio(aspectRatio: 3 / 2, child: image),
                        ),
                      if (image != null) const SizedBox(height: 32),
                      Text(
                        announcement.localizedTitle(languageCode),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.getTextPrimary(brightness),
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        announcement.localizedMessage(languageCode),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                              color: DesignTokens.getTextSecondary(brightness),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (onClose != null)
              PositionedDirectional(
                top: 8,
                end: 8,
                // No `tooltip`: this widget lives in MaterialApp.builder,
                // above the Navigator, so there is no Overlay for it.
                child: Semantics(
                  button: true,
                  label: context.tr('close'),
                  child: IconButton(
                    onPressed: onClose,
                    iconSize: 28,
                    icon: Icon(
                      Icons.close,
                      color: DesignTokens.getTextPrimary(brightness),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
