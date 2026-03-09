import 'dart:ui';

import 'package:camera_translator/features/scan/data/ocr_layout.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract interface class OcrService {
  Future<OcrLayout> recognizeText(String imagePath);
  Future<void> dispose();
}

class MlKitOcrService implements OcrService {
  MlKitOcrService()
    : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<OcrLayout> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);

    final lines = <OcrLine>[];

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isEmpty) continue;

        final r = line.boundingBox; // Rect
        lines.add(
          OcrLine(
            text: t,
            rect: Rect.fromLTRB(r.left, r.top, r.right, r.bottom),
          ),
        );
      }
    }

    return OcrLayout(fullText: recognized.text.trim(), lines: lines);
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
