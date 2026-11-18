import 'package:flutter/material.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';

/// Shows an edition cover as a printed magazine: A4 format, a few paper
/// pages peeking out at the right and bottom edge, a soft binding shadow on
/// the left and a drop shadow below. It is drawn at its own size (centered),
/// not as a full-width header image.
class MagazineCover extends StatelessWidget {
  const MagazineCover({
    super.key,
    required this.imageUrl,
    this.maxWidth = 230,
    this.widthFactor = 0.56,
  });

  final String imageUrl;

  /// Upper limit for the cover width.
  final double maxWidth;

  /// Cover width relative to the available width.
  final double widthFactor;

  static const double _aspect = 1.414; // A4
  static const int _pages = 3;
  static const double _pageStep = 2.5; // offset per page

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final width = (available * widthFactor).clamp(120.0, maxWidth);
      final height = width * _aspect;
      const extra = _pages * _pageStep;

      return Center(
        child: SizedBox(
          width: width + extra,
          height: height + extra,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Paper pages behind the cover (furthest first).
              for (var i = _pages; i >= 1; i--)
                Positioned(
                  left: i * _pageStep,
                  top: i * _pageStep,
                  width: width,
                  height: height,
                  child: _Page(depth: i),
                ),
              // The cover itself.
              Positioned(
                left: 0,
                top: 0,
                width: width,
                height: height,
                child: _Cover(imageUrl: imageUrl),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.depth});

  final int depth;

  @override
  Widget build(BuildContext context) {
    // Paper stays paper-coloured in dark mode too; deeper pages are a touch
    // darker so the edges separate.
    final shade = 0xF6 - depth * 6;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.fromARGB(255, shade, shade - 2, shade - 6),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
        border: Border.all(color: Colors.black.withValues(alpha: 0.10), width: 0.6),
        boxShadow: depth == MagazineCover._pages
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(4, 10),
                ),
              ]
            : null,
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(1.5),
        right: Radius.circular(3),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CorsNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
          // Binding: darker spine with a thin highlight next to it.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0.0, 0.025, 0.045, 0.09, 1.0],
                colors: [
                  Color(0x55000000),
                  Color(0x22000000),
                  Color(0x26FFFFFF),
                  Color(0x00FFFFFF),
                  Color(0x00000000),
                ],
              ),
            ),
          ),
          // Very soft sheen like coated paper.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
