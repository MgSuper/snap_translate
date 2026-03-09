import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class SupportedLanguage {
  final TranslateLanguage language;
  final String code;
  final String label;

  const SupportedLanguage({
    required this.language,
    required this.code,
    required this.label,
  });
}

const supportedLanguages = <SupportedLanguage>[
  SupportedLanguage(
    language: TranslateLanguage.english,
    code: 'en',
    label: 'English',
  ),
  SupportedLanguage(
    language: TranslateLanguage.vietnamese,
    code: 'vi',
    label: 'Vietnamese',
  ),
  SupportedLanguage(
    language: TranslateLanguage.thai,
    code: 'th',
    label: 'Thai',
  ),
  SupportedLanguage(
    language: TranslateLanguage.indonesian,
    code: 'id',
    label: 'Indonesian',
  ),
  SupportedLanguage(
    language: TranslateLanguage.malay,
    code: 'ms',
    label: 'Malay',
  ),
  SupportedLanguage(
    language: TranslateLanguage.chinese,
    code: 'zh',
    label: 'Chinese',
  ),
  SupportedLanguage(
    language: TranslateLanguage.japanese,
    code: 'ja',
    label: 'Japanese',
  ),
  SupportedLanguage(
    language: TranslateLanguage.korean,
    code: 'ko',
    label: 'Korean',
  ),
  SupportedLanguage(
    language: TranslateLanguage.french,
    code: 'fr',
    label: 'French',
  ),
  SupportedLanguage(
    language: TranslateLanguage.german,
    code: 'de',
    label: 'German',
  ),
  SupportedLanguage(
    language: TranslateLanguage.spanish,
    code: 'es',
    label: 'Spanish',
  ),
];
