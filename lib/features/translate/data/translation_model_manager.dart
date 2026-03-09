import 'package:camera_translator/features/translate/data/language_lookup.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract interface class TranslationModelManager {
  Future<bool> ensureModels({
    required TranslateLanguage sourceLang,
    required TranslateLanguage targetLang,
    bool wifiOnly,
  });
}

class MlKitTranslationModelManager implements TranslationModelManager {
  final OnDeviceTranslatorModelManager _mgr = OnDeviceTranslatorModelManager();

  static final _modelNameRegex = RegExp(r'^[a-z]{2,3}_[a-z]{2,3}$');

  @override
  Future<bool> ensureModels({
    required TranslateLanguage sourceLang,
    required TranslateLanguage targetLang,
    bool wifiOnly = false,
  }) async {
    final src = codeOf(sourceLang).trim().toLowerCase();
    final tgt = codeOf(targetLang).trim().toLowerCase();

    final modelName = '${src}_$tgt';
    // 1. Download Source Language Pack
    final bool sourceDownloaded = await _mgr.downloadModel(
      src,
      isWifiRequired: wifiOnly,
    );

    // 2. Download Target Language Pack
    final bool targetDownloaded = await _mgr.downloadModel(
      tgt,
      isWifiRequired: wifiOnly,
    );

    return sourceDownloaded && targetDownloaded;
  }
}
