import 'package:camera_translator/features/scan/data/ocr_layout.dart';

class ResultArgs {
  const ResultArgs({required this.imagePath, required this.layout});

  final String imagePath;
  final OcrLayout layout;
}
