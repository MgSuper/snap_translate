import 'package:camera_translator/features/scan/data/ocr_layout.dart';

sealed class ScanState {
  const ScanState();
}

final class ScanIdle extends ScanState {
  const ScanIdle();
}

final class ScanProcessing extends ScanState {
  const ScanProcessing();
}

final class ScanSuccess extends ScanState {
  const ScanSuccess({required this.imagePath, required this.layout});

  final String imagePath;
  final OcrLayout layout;
}

final class ScanFailure extends ScanState {
  const ScanFailure(this.message);
  final String message;
}
