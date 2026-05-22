import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jugendkompass_app/presentation/widgets/verse/verse_share_card.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';

/// Service to render a [VerseShareCard] to an image and open the native
/// OS share sheet.  Not supported on web.
class VerseShareService {
  VerseShareService._();

  /// Renders [verse] as a PNG and opens the native share sheet.
  /// On web this is a no-op (file sharing not supported by browsers).
  static Future<void> shareVerse({
    required VerseModel verse,
    required BuildContext context,
    String subject = 'Vers des Tages',
  }) async {
    if (kIsWeb) {
      // Web cannot share binary files via share_plus – show a snackbar.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teilen ist nur in der App (iOS/Android) verfügbar.'),
          ),
        );
      }
      return;
    }

    try {
      final controller = ScreenshotController();

      // Capture the share card widget completely off-screen.
      final Uint8List pngBytes = await controller.captureFromLongWidget(
        VerseShareCard(verse: verse),
        pixelRatio: 3.0,
        context: context,
      );

      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/vers_des_tages.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: subject,
      );
    } catch (e) {
      debugPrint('[VerseShareService] Fehler beim Teilen: $e');
    }
  }
}
