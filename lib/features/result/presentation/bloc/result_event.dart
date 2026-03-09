import 'package:google_mlkit_translation/google_mlkit_translation.dart';

sealed class ResultEvent {
  const ResultEvent();
}

final class ResultTranslatePressed extends ResultEvent {
  const ResultTranslatePressed();
}

final class ResultSwapLanguagesPressed extends ResultEvent {
  const ResultSwapLanguagesPressed();
}

final class ResultSourceLangChanged extends ResultEvent {
  const ResultSourceLangChanged(this.language);
  final TranslateLanguage language;
}

final class ResultTargetLangChanged extends ResultEvent {
  const ResultTargetLangChanged(this.language);
  final TranslateLanguage language;
}

final class ResultOriginalTextChanged extends ResultEvent {
  const ResultOriginalTextChanged(this.text);
  final String text;
}

final class ResultAutoDetectRequested extends ResultEvent {
  const ResultAutoDetectRequested();
}

final class ResultInitRequested extends ResultEvent {
  const ResultInitRequested();
}
