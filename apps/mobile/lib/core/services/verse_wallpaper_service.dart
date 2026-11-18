import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/data/repositories/verse_repository.dart';
import 'package:jugendkompass_app/data/services/supabase_service.dart';

/// "Als Hintergrundbild": renders the verse of the day (in the app language)
/// on its nature photo in the phone's screen format and hands it to the
/// system:
///  * Android – opens the system "set as wallpaper" screen directly
///    (home / lock screen choice), see MainActivity.kt.
///  * iOS – Apple allows no app to set the wallpaper; the share sheet opens
///    with the image, where "Use as Wallpaper" is offered.
class VerseWallpaperService {
  VerseWallpaperService._();

  static const _channel = MethodChannel('jugendkompass/wallpaper');

  static Future<void> setAsWallpaper(BuildContext context, VerseModel verse) async {
    final view = View.of(context);
    final ratio = view.devicePixelRatio;
    final logical = view.physicalSize / ratio;
    // Render at the phone's real resolution (capped for memory).
    final scale = (ratio).clamp(2.0, 3.0);
    final w = (logical.width * scale).round().clamp(720, 1440);
    final h = (w * logical.height / logical.width).round();

    final photo = await _loadPhoto(verse.backgroundImageUrl, w, h);
    final png = await _render(verse, w, h, photo);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vers_hintergrund.png');
    await file.writeAsBytes(png, flush: true);
    VerseRepository(SupabaseService.instance.client).incrementUsage(verse.id);

    if (!kIsWeb && Platform.isAndroid) {
      await _channel.invokeMethod('setWallpaper', {'path': file.path});
    } else {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: AppTranslations.t('verse_of_day'),
      );
    }
  }

  /// High-resolution version of the verse photo (the stored one is 480 px for
  /// the widget); falls back to the stored photo, then to a gradient.
  static Future<ui.Image?> _loadPhoto(String? url, int w, int h) async {
    final candidates = <String>[];
    final id = RegExp(r'/backgrounds/(?:w480/)?(\d+)\.jpg').firstMatch(url ?? '')?.group(1);
    if (id != null) candidates.add('https://picsum.photos/id/$id/$w/$h');
    if (url != null && url.isNotEmpty) candidates.add(url);
    for (final u in candidates) {
      try {
        final res = await http.get(Uri.parse(u)).timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) continue;
        final codec = await ui.instantiateImageCodec(res.bodyBytes);
        return (await codec.getNextFrame()).image;
      } catch (_) {/* try next */}
    }
    return null;
  }

  static Future<Uint8List> _render(VerseModel verse, int w, int h, ui.Image? photo) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());

    if (photo != null) {
      // cover-fit
      final src = photo.width / photo.height;
      final dst = w / h;
      final Rect from = src > dst
          ? Rect.fromLTWH((photo.width - photo.height * dst) / 2, 0, photo.height * dst, photo.height.toDouble())
          : Rect.fromLTWH(0, (photo.height - photo.width / dst) / 2, photo.width.toDouble(), photo.width / dst);
      canvas.drawImageRect(photo, from, rect, Paint()..filterQuality = FilterQuality.high);
    } else {
      canvas.drawRect(rect, Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3E4A5E), Color(0xFF8B0000)],
        ).createShader(rect));
    }
    // Darken for legibility (stronger towards the text in the lower half).
    canvas.drawRect(rect, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.55)],
      ).createShader(rect));

    final maxText = w * 0.82;
    final de = AppTranslations.currentLanguage == AppLanguage.de;
    final verseText = de ? '„${_clean(verse.verse)}“' : '“${_clean(verse.verse)}”';
    var size = w * 0.068;
    late TextPainter versePainter;
    // Shrink long verses so they fit into ~40 % of the screen height.
    do {
      versePainter = TextPainter(
        text: TextSpan(text: verseText, style: TextStyle(
          color: Colors.white, fontSize: size, height: 1.35, fontWeight: FontWeight.w600,
          fontFamily: 'serif', shadows: const [Shadow(color: Colors.black54, blurRadius: 12)],
        )),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxText);
      size *= 0.92;
    } while (versePainter.height > h * 0.40 && size > w * 0.035);

    final refPainter = TextPainter(
      text: TextSpan(text: _clean(verse.reference).toUpperCase(), style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9), fontSize: w * 0.034,
        letterSpacing: w * 0.006, fontWeight: FontWeight.w600,
      )),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxText);
    final brand = TextPainter(
      text: TextSpan(text: 'JUGENDKOMPASS', style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7), fontSize: w * 0.026,
        letterSpacing: w * 0.008, fontWeight: FontWeight.w700,
      )),
      textDirection: TextDirection.ltr,
    )..layout();

    // Text block centred a little below the middle (clock/widgets sit on top).
    final gap = w * 0.05;
    final block = versePainter.height + gap + refPainter.height;
    final top = h * 0.56 - block / 2;
    versePainter.paint(canvas, Offset((w - versePainter.width) / 2, top));
    final lineY = top + versePainter.height + gap * 0.5;
    canvas.drawLine(Offset(w / 2 - w * 0.06, lineY), Offset(w / 2 + w * 0.06, lineY),
        Paint()..color = Colors.white70..strokeWidth = w * 0.003);
    refPainter.paint(canvas, Offset((w - refPainter.width) / 2, top + versePainter.height + gap));
    brand.paint(canvas, Offset((w - brand.width) / 2, h * 0.93));

    final image = await recorder.endRecording().toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static String _clean(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll('&nbsp;', ' ').trim();
}
