import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Load the original logo
  final inputPath = 'assets/images/logo_trans.png';
  final outputPath = 'assets/images/logo_foreground.png';

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('Input file not found: $inputPath');
    exit(1);
  }

  final inputBytes = inputFile.readAsBytesSync();
  final original = img.decodeImage(inputBytes);

  if (original == null) {
    print('Failed to decode image');
    exit(1);
  }

  print('Original size: ${original.width}x${original.height}');

  // Create a 1024x1024 canvas with transparent background
  final canvasSize = 1024;
  final canvas = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);

  // Fill with transparent
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  // Scale logo to 60% of canvas (leaves 20% padding on each side)
  final logoSize = (canvasSize * 0.60).round();
  final resized = img.copyResize(original, width: logoSize, height: logoSize, interpolation: img.Interpolation.cubic);

  // Center the logo on canvas
  final offset = ((canvasSize - logoSize) / 2).round();

  // Composite the resized logo onto the canvas
  img.compositeImage(canvas, resized, dstX: offset, dstY: offset);

  // Save as PNG with transparency
  final outputBytes = img.encodePng(canvas);
  File(outputPath).writeAsBytesSync(outputBytes);

  print('Created adaptive icon: $outputPath');
  print('Logo size: ${logoSize}x$logoSize (60% of canvas)');
  print('Padding: $offset pixels on each side');
}
