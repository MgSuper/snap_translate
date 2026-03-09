import 'package:camera_translator/features/receipt/domain/receipt_summary.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

sealed class ResultState {
  const ResultState({
    required this.sourceLang,
    required this.targetLang,
    required this.originalText,
    required this.translatedText,
    required this.summary,
  });

  final TranslateLanguage sourceLang;
  final TranslateLanguage targetLang;
  final String originalText;
  final String translatedText;
  final ReceiptSummary? summary;
}

final class ResultIdle extends ResultState {
  const ResultIdle({
    required super.sourceLang,
    required super.targetLang,
    required super.originalText,
    super.translatedText = '',
    super.summary,
  });
}

final class ResultDownloadingModels extends ResultState {
  const ResultDownloadingModels({
    required super.sourceLang,
    required super.targetLang,
    required super.originalText,
    required super.translatedText,
    super.summary,
  });
}

final class ResultTranslating extends ResultState {
  const ResultTranslating({
    required super.sourceLang,
    required super.targetLang,
    required super.originalText,
    required super.translatedText,
    super.summary,
  });
}

final class ResultSaved extends ResultState {
  const ResultSaved({
    required super.sourceLang,
    required super.targetLang,
    required super.originalText,
    required super.translatedText,
    super.summary,
  });
}

final class ResultFailure extends ResultState {
  const ResultFailure({
    required super.sourceLang,
    required super.targetLang,
    required super.originalText,
    required super.translatedText,
    super.summary,
    required this.message,
  });

  final String message;
}
