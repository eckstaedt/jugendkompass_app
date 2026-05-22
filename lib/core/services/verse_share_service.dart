import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
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

  /// Capture the verse card as PNG bytes
  static Future<Uint8List> _captureVerseCard(VerseModel verse) async {
    return await _controller.captureFromWidget(
      VerseShareCard(verse: verse),
      pixelRatio: 3.0,
      targetSize: const Size(360, 560),
    );
  }

  /// Share verse via native share sheet
  static Future<void> shareVerse(VerseModel verse) async {
    try {
      final Uint8List pngBytes = await _captureVerseCard(verse);

      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/vers_des_tages.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Vers des Tages',
      );
    } catch (e) {
      debugPrint('[VerseShareService] Fehler beim Teilen: $e');
      rethrow;
    }
  }

  /// Save verse image directly to device gallery/photos
  static Future<bool> saveToGallery(VerseModel verse) async {
    try {
      final Uint8List pngBytes = await _captureVerseCard(verse);

      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/vers_des_tages_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(file.path, album: 'Jugendkompass');

      // Clean up temp file
      await file.delete();

      return true;
    } catch (e) {
      debugPrint('[VerseShareService] Fehler beim Speichern: $e');
      return false;
    }
  }

  /// Check if we have permission to save to gallery
  static Future<bool> hasGalleryAccess() async {
    return await Gal.hasAccess();
  }

  /// Request permission to save to gallery
  static Future<bool> requestGalleryAccess() async {
    return await Gal.requestAccess();
  }
}
