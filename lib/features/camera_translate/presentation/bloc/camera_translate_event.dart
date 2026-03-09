import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract class CameraTranslateEvent {
  const CameraTranslateEvent();
}

class CameraTranslateTargetLanguageChanged extends CameraTranslateEvent {
  const CameraTranslateTargetLanguageChanged(this.language);

  final TranslateLanguage language;
}

class CameraTranslateScanRequested extends CameraTranslateEvent {
  const CameraTranslateScanRequested(this.imagePath);

  final String imagePath;
}

class CameraTranslateCaptureRequested extends CameraTranslateEvent {
  const CameraTranslateCaptureRequested({required this.savedImagePath});

  final String savedImagePath;
}

class CameraTranslateClearRequested extends CameraTranslateEvent {
  const CameraTranslateClearRequested();
}
