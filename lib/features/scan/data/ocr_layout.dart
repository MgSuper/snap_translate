import 'dart:ui';

class OcrLine {
  const OcrLine({required this.text, required this.rect});

  final String text;
  final Rect rect;

  double get centerY => rect.top + rect.height / 2;
  double get centerX => rect.left + rect.width / 2;
}

class OcrLayout {
  const OcrLayout({required this.fullText, required this.lines});

  /// Full joined text (still useful for fallback).
  final String fullText;

  /// Flat list of lines with bounding boxes.
  final List<OcrLine> lines;
}
