import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' as ui;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class TranslatedPosterRenderer {
  /// Returns the saved PNG file path.
  Future<String> renderPng({
    required String originalImagePath,
    required String translatedText,
    required String headerLine, // e.g. "VI → EN"
    required DateTime createdAt,
  });
}

class CanvasTranslatedPosterRenderer implements TranslatedPosterRenderer {
  @override
  Future<String> renderPng({
    required String originalImagePath,
    required String translatedText,
    required String headerLine,
    required DateTime createdAt,
  }) async {
    final bytes = await File(originalImagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;

    // Layout constants (tweak later)
    const padding = 24.0;
    const gap = 18.0;
    const headerFontSize = 22.0;
    const bodyFontSize = 18.0;
    const lineHeight = 1.35;

    // Target render width: keep receipt width, but cap to avoid huge canvases
    final targetWidth = img.width.toDouble().clamp(720.0, 1080.0);

    // Scale receipt image to target width
    final scale = targetWidth / img.width.toDouble();
    final receiptW = targetWidth;
    final receiptH = img.height.toDouble() * scale;

    // Prepare text painters to measure height
    final headerPainter = _buildPainter(
      text: headerLine,
      fontSize: headerFontSize,
      maxWidth: targetWidth - padding * 2,
      bold: true,
      height: 1.2,
    );

    final bodyPainter = _buildPainter(
      text: translatedText.trim().isEmpty ? '—' : translatedText.trim(),
      fontSize: bodyFontSize,
      maxWidth: targetWidth - padding * 2,
      bold: false,
      height: lineHeight,
    );

    // Total canvas height
    final canvasW = targetWidth;
    final canvasH =
        padding +
        receiptH +
        gap +
        headerPainter.height +
        10 +
        bodyPainter.height +
        padding;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, canvasW, canvasH),
    );

    // Background
    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, canvasW, canvasH), bgPaint);

    // Draw receipt image scaled
    final dstRect = ui.Rect.fromLTWH(
      padding,
      padding,
      receiptW - padding * 2,
      receiptH,
    );
    final srcRect = ui.Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    canvas.drawImageRect(img, srcRect, dstRect, ui.Paint());

    // Divider line
    final yDivider = padding + receiptH + gap * 0.6;
    canvas.drawLine(
      ui.Offset(padding, yDivider),
      ui.Offset(canvasW - padding, yDivider),
      ui.Paint()
        ..color = const ui.Color(0xFFDDDDDD)
        ..strokeWidth = 2,
    );

    // Header
    final headerOffset = ui.Offset(padding, yDivider + gap * 0.6);
    headerPainter.paint(canvas, headerOffset);

    // Body
    final bodyOffset = ui.Offset(
      padding,
      headerOffset.dy + headerPainter.height + 10,
    );
    bodyPainter.paint(canvas, bodyOffset);

    final picture = recorder.endRecording();
    final outImg = await picture.toImage(canvasW.toInt(), canvasH.toInt());
    final pngBytes = await outImg.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes == null) {
      throw StateError('Failed to encode PNG');
    }

    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(dir.path, 'posters'));
    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    final name = 'poster_${createdAt.microsecondsSinceEpoch}.png';
    final outPath = p.join(outDir.path, name);

    await File(outPath).writeAsBytes(pngBytes.buffer.asUint8List());

    if (kDebugMode) {
      debugPrint('[POSTER] saved: $outPath');
    }

    return outPath;
  }

  ui.TextPainter _buildPainter({
    required String text,
    required double fontSize,
    required double maxWidth,
    required bool bold,
    required double height,
  }) {
    final span = ui.TextSpan(
      text: text,
      style: ui.TextStyle(
        color: const ui.Color(0xFF111111),
        fontSize: fontSize,
        fontWeight: bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
        height: height,
      ),
    );

    final painter = ui.TextPainter(
      text: span,
      textDirection: ui.TextDirection.ltr,
      maxLines: null,
    );

    painter.layout(maxWidth: maxWidth);
    return painter;
  }
}
