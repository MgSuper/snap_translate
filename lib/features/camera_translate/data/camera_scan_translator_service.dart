import 'dart:io';
import 'dart:ui';
import 'package:image/image.dart' as img;

import 'package:camera_translator/features/camera_translate/presentation/overlay_text_item.dart';
import 'package:camera_translator/features/translate/data/language_lookup.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract interface class CameraScanTranslatorService {
  Future<List<OverlayTextItem>> scanAndTranslate({
    required String imagePath,
    required TranslateLanguage targetLanguage,
  });

  Future<void> close();
}

class MlKitCameraScanTranslatorService implements CameraScanTranslatorService {
  MlKitCameraScanTranslatorService({
    TextRecognizer? textRecognizer,
    LanguageIdentifier? languageIdentifier,
  }) : _textRecognizer =
           textRecognizer ??
           TextRecognizer(script: TextRecognitionScript.latin),
       _languageIdentifier =
           languageIdentifier ?? LanguageIdentifier(confidenceThreshold: 0.5);

  final TextRecognizer _textRecognizer;
  final LanguageIdentifier _languageIdentifier;

  final Map<String, String> _translationCache = {};
  final Map<String, Rect> _stableRects = {};

  String _cacheKey(String text, TranslateLanguage target) {
    return '$text::$target';
  }

  String _trackingKey(OverlayTextItem item) {
    return item.translatedText.trim().toLowerCase();
  }

  Rect _smoothRect(Rect oldRect, Rect newRect) {
    const alpha =
        0.65; // higher = more stable, lower = more responsive, if too laggy reduce this

    double lerp(double a, double b) => a * alpha + b * (1 - alpha);

    return Rect.fromLTWH(
      lerp(oldRect.left, newRect.left),
      lerp(oldRect.top, newRect.top),
      lerp(oldRect.width, newRect.width),
      lerp(oldRect.height, newRect.height),
    );
  }

  @override
  Future<List<OverlayTextItem>> scanAndTranslate({
    required String imagePath,
    required TranslateLanguage targetLanguage,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _textRecognizer.processImage(inputImage);

    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw StateError('Failed to decode image size');
    }

    final imageWidth = decoded.width.toDouble();
    final imageHeight = decoded.height.toDouble();

    if (recognized.blocks.isEmpty) {
      return const [];
    }

    final overlays = <OverlayTextItem>[];

    for (final block in recognized.blocks) {
      final original = cleanBlockText(block.text);
      if (!shouldTranslateBlock(original)) continue;

      final detectedCode = await _languageIdentifier.identifyLanguage(original);
      final detectedLanguage = mapDetectedLanguage(detectedCode);

      String translated = original;

      if (detectedLanguage != null && detectedLanguage != targetLanguage) {
        final key = _cacheKey(original, targetLanguage);

        if (_translationCache.containsKey(key)) {
          translated = _translationCache[key]!;
        } else {
          final translator = OnDeviceTranslator(
            sourceLanguage: detectedLanguage,
            targetLanguage: targetLanguage,
          );

          try {
            final out = await translator.translateText(original);
            translated = out.trim();

            if (translated.isNotEmpty) {
              _translationCache[key] = translated;

              if (_translationCache.length > 200) {
                _translationCache.clear();
              }
            }
          } finally {
            await translator.close();
          }
        }
      }

      overlays.add(
        OverlayTextItem(
          originalText: original,
          translatedText: translated,
          rect: block.boundingBox,
          imageSize: Size(imageWidth, imageHeight),
        ),
      );
    }

    final stabilized = <OverlayTextItem>[];
    final seenKeys = <String>{};

    for (final item in overlays) {
      final key = _trackingKey(item);
      seenKeys.add(key);

      final previousRect = _stableRects[key];
      final rect = previousRect == null
          ? item.rect
          : _smoothRect(previousRect, item.rect);

      _stableRects[key] = rect;

      stabilized.add(
        OverlayTextItem(
          originalText: item.originalText,
          translatedText: item.translatedText,
          rect: rect,
          imageSize: item.imageSize,
        ),
      );
    }

    // Remove stale keys not seen in this frame
    _stableRects.removeWhere((key, _) => !seenKeys.contains(key));

    return stabilized;
  }

  @override
  Future<void> close() async {
    await _textRecognizer.close();
    await _languageIdentifier.close();
  }
}

String cleanBlockText(String text) {
  return text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool shouldTranslateBlock(String text) {
  if (text.isEmpty) return false;

  if (text.length < 3) return false;

  // Only digits / punctuation
  if (RegExp(r'^[\d\s\W]+$').hasMatch(text)) return false;

  // Mostly digits
  final digitCount = RegExp(r'\d').allMatches(text).length;
  if (digitCount >= text.replaceAll(' ', '').length * 0.5) return false;

  // Single short token like "8", "KB"
  final words = text.split(' ').where((e) => e.isNotEmpty).toList();
  if (words.length == 1 && words.first.length <= 2) return false;

  return true;
}

TranslateLanguage? mapDetectedLanguage(String code) {
  if (code == 'und') return null;
  return translateLanguageFromCode(code);
}
