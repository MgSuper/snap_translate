import 'package:bloc_test/bloc_test.dart';
import 'package:camera_translator/features/history/repository/history_repository.dart';
import 'package:camera_translator/features/result/presentation/bloc/result_bloc.dart';
import 'package:camera_translator/features/result/presentation/bloc/result_event.dart';
import 'package:camera_translator/features/result/presentation/bloc/result_state.dart';
import 'package:camera_translator/features/translate/data/language_id_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import 'package:camera_translator/features/history/data/scan_record.dart';
import 'package:camera_translator/features/translate/data/translation_model_manager.dart';
import 'package:camera_translator/features/translate/data/translation_service.dart';

class _MockTranslator extends Mock implements TranslationService {}

class _MockModelManager extends Mock implements TranslationModelManager {}

class _MockHistoryRepo extends Mock implements HistoryRepository {}

class _MockIdService extends Mock implements LanguageIdService {}

void main() {
  late TranslationService translator;
  late TranslationModelManager modelManager;
  late HistoryRepository historyRepo;
  late LanguageIdService idService;

  setUpAll(() {
    // ✅ Required by mocktail when using any() with TranslateLanguage params
    registerFallbackValue(TranslateLanguage.english);

    // ✅ Required by mocktail when using any() with ScanRecord params
    registerFallbackValue(
      ScanRecord(
        id: 'fallback',
        createdAt: DateTime(2026, 1, 1),
        sourceLang: 'en',
        targetLang: 'vi',
        originalText: 'x',
        translatedText: 'y',
      ),
    );
  });

  setUp(() {
    translator = _MockTranslator();
    modelManager = _MockModelManager();
    historyRepo = _MockHistoryRepo();
    idService = _MockIdService();
  });

  blocTest<ResultBloc, ResultState>(
    'downloads models, translates, saves, then emits ResultSaved',
    build: () {
      when(
        () => modelManager.ensureModels(
          sourceLang: any(named: 'sourceLang'),
          targetLang: any(named: 'targetLang'),
          wifiOnly: any(named: 'wifiOnly'),
        ),
      ).thenAnswer((_) async => true);

      when(
        () => translator.translate(
          text: any(named: 'text'),
          sourceLang: any(named: 'sourceLang'),
          targetLang: any(named: 'targetLang'),
        ),
      ).thenAnswer((_) async => 'Xin chào');

      when(() => historyRepo.upsert(any())).thenAnswer((_) async {});

      return ResultBloc(
        translator: translator,
        modelManager: modelManager,
        historyRepo: historyRepo,
        initialText: 'hello',
        languageIdService: idService,
      );
    },
    act: (bloc) => bloc.add(const ResultTranslatePressed()),
    expect: () => [
      isA<ResultDownloadingModels>(),
      isA<ResultTranslating>(),
      isA<ResultSaved>().having(
        (s) => s.translatedText,
        'translatedText',
        'Xin chào',
      ),
    ],
    verify: (_) {
      verify(
        () => modelManager.ensureModels(
          sourceLang: TranslateLanguage.english,
          targetLang: TranslateLanguage.vietnamese,
          wifiOnly: false,
        ),
      ).called(1);

      verify(
        () => translator.translate(
          text: 'hello',
          sourceLang: TranslateLanguage.english,
          targetLang: TranslateLanguage.vietnamese,
        ),
      ).called(1);

      verify(() => historyRepo.upsert(any())).called(1);
    },
  );

  blocTest<ResultBloc, ResultState>(
    'emits Failure when original text is empty',
    build: () => ResultBloc(
      translator: translator,
      modelManager: modelManager,
      historyRepo: historyRepo,
      initialText: '   ',
      languageIdService: idService,
    ),
    act: (bloc) => bloc.add(const ResultTranslatePressed()),
    expect: () => [
      isA<ResultFailure>().having(
        (s) => s.message,
        'message',
        'Nothing to translate.',
      ),
    ],
  );
}
