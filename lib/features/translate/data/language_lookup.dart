import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'supported_languages.dart';

String codeOf(TranslateLanguage lang) =>
    supportedLanguages.firstWhere((e) => e.language == lang).code;

String labelOf(TranslateLanguage lang) =>
    supportedLanguages.firstWhere((e) => e.language == lang).label;

TranslateLanguage? translateLanguageFromCode(String code) {
  final normalized = code.trim().toLowerCase();
  for (final l in supportedLanguages) {
    if (l.code == normalized) return l.language;
  }
  return null;
}
