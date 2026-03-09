import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract interface class TranslationService {
  Future<String> translate({
    required String text,
    required TranslateLanguage sourceLang,
    required TranslateLanguage targetLang,
  });
}

class MlKitTranslationService implements TranslationService {
  @override
  Future<String> translate({
    required String text,
    required TranslateLanguage sourceLang,
    required TranslateLanguage targetLang,
  }) async {
    final translator = OnDeviceTranslator(
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
    );

    try {
      final out = await translator.translateText(text);
      return out.trim();
    } finally {
      await translator.close();
    }
  }
}
