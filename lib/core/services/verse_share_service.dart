import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/presentation/widgets/verse/verse_share_card.dart';

/// Shares the verse image – uses the admin-uploaded image if available,
/// falls back to the Flutter-rendered card otherwise.
class VerseShareService {
  VerseShareService._();

  static final ScreenshotController _controller = ScreenshotController();

  /// Downloads the image from [url] and returns its bytes.
  static Future<Uint8List> _downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Bild konnte nicht geladen werden (${response.statusCode})');
    }
    return response.bodyBytes;
  }

  /// Renders the Flutter share card as PNG bytes (fallback).
  static Future<Uint8List> _captureVerseCard(VerseModel verse) async {
    return await _controller.captureFromWidget(
      VerseShareCard(verse: verse),
      pixelRatio: 3.0,
      targetSize: const Size(360, 560),
    );
  }

  /// Returns the image bytes for sharing:
  /// - Admin-uploaded image (imageUrl) if available
  /// - Flutter-rendered card as fallback
  static Future<Uint8List> _getImageBytes(VerseModel verse) async {
    if (verse.imageUrl != null && verse.imageUrl!.isNotEmpty) {
      return await _downloadImage(verse.imageUrl!);
    }
    return await _captureVerseCard(verse);
  }

  /// Share verse via native share sheet.
  static Future<void> shareVerse(VerseModel verse) async {
    try {
      final Uint8List bytes = await _getImageBytes(verse);
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/vers_des_tages.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Vers des Tages',
      );
    } catch (e) {
      debugPrint('[VerseShareService] Fehler beim Teilen: $e');
      rethrow;
    }
  }

  /// Save verse image directly to device gallery/photos.
  static Future<bool> saveToGallery(VerseModel verse) async {
    try {
      final Uint8List bytes = await _getImageBytes(verse);
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/vers_des_tages_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      await Gal.putImage(file.path, album: 'Jugendkompass');
      await file.delete();
      return true;
    } catch (e) {
      debugPrint('[VerseShareService] Fehler beim Speichern: $e');
      return false;
    }
  }

  /// Check if we have permission to save to gallery.
  static Future<bool> hasGalleryAccess() async {
    return await Gal.hasAccess();
  }

  /// Request permission to save to gallery.
  static Future<bool> requestGalleryAccess() async {
    return await Gal.requestAccess();
  }
}
