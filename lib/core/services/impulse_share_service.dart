import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/utils/html_utils.dart';
import 'package:jugendkompass_app/data/models/impulse_model.dart';
import 'package:jugendkompass_app/presentation/widgets/impulse/impulse_share_card.dart';

/// Renders and shares an image for an impulse (only when it has a picture).
class ImpulseShareService {
  ImpulseShareService._();

  static final ScreenshotController _controller = ScreenshotController();

  static bool canShareImage(ImpulseModel impulse) =>
      impulse.imageUrl != null && impulse.imageUrl!.isNotEmpty;

  static Future<Uint8List> _render(ImpulseModel impulse) async {
    final response = await http.get(Uri.parse(impulse.imageUrl!));
    if (response.statusCode != 200) {
      throw Exception('Bild konnte nicht geladen werden (${response.statusCode})');
    }
    return _controller.captureFromWidget(
      ImpulseShareCard(
        imageBytes: response.bodyBytes,
        title: HtmlUtils.stripHtml(impulse.displayTitle),
        label: AppTranslations.t('impulse_badge'),
      ),
      pixelRatio: 3.0,
      targetSize: ImpulseShareCard.size,
      delay: const Duration(milliseconds: 300),
    );
  }

  static Future<File> _writeTemp(Uint8List bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Opens the native share sheet with the rendered image.
  static Future<void> shareImage(ImpulseModel impulse) async {
    try {
      final file = await _writeTemp(await _render(impulse), 'impuls.png');
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: HtmlUtils.stripHtml(impulse.displayTitle),
      );
    } catch (e) {
      debugPrint('[ImpulseShareService] share failed: $e');
      rethrow;
    }
  }

  /// Saves the rendered image to the photo library.
  static Future<bool> saveToGallery(ImpulseModel impulse) async {
    try {
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) return false;
      final file = await _writeTemp(
        await _render(impulse),
        'impuls_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await Gal.putImage(file.path, album: 'Jugendkompass');
      await file.delete();
      return true;
    } catch (e) {
      debugPrint('[ImpulseShareService] save failed: $e');
      return false;
    }
  }
}
