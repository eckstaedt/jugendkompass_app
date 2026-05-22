import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/presentation/widgets/verse/verse_share_card.dart';

/// Renders a [VerseShareCard] entirely off-screen (no widget tree insertion)
/// and shares the resulting PNG via the native OS share sheet.
class VerseShareService {
  VerseShareService._();

  static final ScreenshotController _controller = ScreenshotController();

  static Future<void> shareVerse(VerseModel verse) async {
    try {
      // captureFromWidget renders the widget without adding it to the tree,
      // so there are no layout constraints / overflow issues on any platform.
      final Uint8List pngBytes = await _controller.captureFromWidget(
        VerseShareCard(verse: verse),
        pixelRatio: 3.0,
        targetSize: const Size(360, 560),
      );

      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/vers_des_tages.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Vers des Tages',
      );
    } catch (e) {
      debugPrint('[VerseShareService] Fehler beim Teilen: $e');
    }
  }
}
