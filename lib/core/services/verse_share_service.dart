import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service to render a verse widget to an image and share it via the
/// native OS share sheet.
class VerseShareService {
  VerseShareService._();

  /// Captures the widget attached to [boundaryKey] as a PNG, saves it to a
  /// temporary file and opens the native share sheet.
  ///
  /// [subject] is used as the email subject / message preview where supported.
  static Future<void> shareVerseImage({
    required GlobalKey boundaryKey,
    String subject = 'Vers des Tages',
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Render at 3× device pixel ratio for crisp output on high-DPI screens.
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Write to a temporary file.
      final Directory tempDir = await getTemporaryDirectory();
      final File file =
          File('${tempDir.path}/vers_des_tages.png');
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
