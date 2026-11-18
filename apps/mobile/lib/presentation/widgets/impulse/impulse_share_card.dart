import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jugendkompass_app/core/config/app_fonts.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

/// Image that is shared for an impulse (portrait 4:5):
/// the impulse image as a square on top, title and branding below.
class ImpulseShareCard extends StatelessWidget {
  const ImpulseShareCard({
    super.key,
    required this.imageBytes,
    required this.title,
    required this.label,
  });

  static const Size size = Size(360, 450);

  final Uint8List imageBytes;
  final String title;

  /// Small caption, e.g. "Impuls".
  final String label;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.fromSize(
          size: size,
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: size.width,
                  child: Image.memory(imageBytes, fit: BoxFit.cover, gaplessPlayback: true),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppFonts.ui,
                                  fontSize: 16,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                  color: DesignTokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'JUGENDKOMPASS · ${label.toUpperCase()}',
                                style: const TextStyle(
                                  fontFamily: AppFonts.ui,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: DesignTokens.primaryRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset('assets/images/logo.png', width: 44, height: 44),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
