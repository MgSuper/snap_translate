import 'package:camera_translator/features/translate/data/language_lookup.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract interface class CameraTranslateModelManager {
  Future<void> ensureTargetModelReady(TranslateLanguage language);
}

class MlKitCameraTranslateModelManager implements CameraTranslateModelManager {
  final OnDeviceTranslatorModelManager _manager =
      OnDeviceTranslatorModelManager();

  @override
  Future<void> ensureTargetModelReady(TranslateLanguage language) async {
    final code = codeOf(language);
    final downloaded = await _manager.isModelDownloaded(code);

    if (downloaded) return;

    final ok = await _manager
        .downloadModel(code)
        .timeout(const Duration(seconds: 30));
    if (!ok) {
      throw StateError('Failed to download language pack for $code');
    }
  }
}
