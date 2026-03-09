import 'dart:ui';

class OverlayTextItem {
  const OverlayTextItem({
    required this.originalText,
    required this.translatedText,
    required this.rect,
    required this.imageSize,
  });

  final String originalText;
  final String translatedText;
  final Rect rect;
  final Size imageSize;
}
