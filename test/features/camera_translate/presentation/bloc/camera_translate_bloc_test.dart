import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:camera_translator/features/camera_translate/data/camera_scan_translator_service.dart';
import 'package:camera_translator/features/camera_translate/data/camera_translate_model_manager.dart';
import 'package:camera_translator/features/camera_translate/presentation/bloc/camera_translate_bloc.dart';
import 'package:camera_translator/features/camera_translate/presentation/bloc/camera_translate_event.dart';
import 'package:camera_translator/features/camera_translate/presentation/bloc/camera_translate_state.dart';
import 'package:camera_translator/features/camera_translate/presentation/overlay_text_item.dart';
import 'package:camera_translator/features/history/data/scan_record.dart';
import 'package:camera_translator/features/history/repository/history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:mocktail/mocktail.dart';

class _MockScanTranslator extends Mock implements CameraScanTranslatorService {}

class _MockHistoryRepository extends Mock implements HistoryRepository {}

class _MockModelManager extends Mock implements CameraTranslateModelManager {}

void main() {
  late CameraScanTranslatorService scanTranslator;
  late HistoryRepository historyRepository;
  late CameraTranslateModelManager modelManager;

  setUpAll(() {
    registerFallbackValue(TranslateLanguage.english);
    registerFallbackValue(
      ScanRecord(
        id: '1',
        createdAt: DateTime(2025, 1, 1),
        sourceLang: 'auto',
        targetLang: 'en',
        originalText: 'a',
        translatedText: 'b',
        summaryJson: null,
        originalImagePath: '/tmp/a.png',
        renderedImagePath: '/tmp/a.png',
      ),
    );
  });

  setUp(() {
    scanTranslator = _MockScanTranslator();
    historyRepository = _MockHistoryRepository();
    modelManager = _MockModelManager();

    when(
      () => modelManager.ensureTargetModelReady(any()),
    ).thenAnswer((_) async {});

    when(() => scanTranslator.close()).thenAnswer((_) async {});
  });

  blocTest<CameraTranslateBloc, CameraTranslateState>(
    'target language changes',
    build: () => CameraTranslateBloc(
      scanTranslator: scanTranslator,
      historyRepository: historyRepository,
      modelManager: modelManager,
    ),
    act: (bloc) => bloc.add(
      const CameraTranslateTargetLanguageChanged(TranslateLanguage.vietnamese),
    ),
    expect: () => [
      isA<CameraTranslateState>()
          .having((s) => s.isDownloadingModel, 'isDownloadingModel', true)
          .having(
            (s) => s.targetLanguage,
            'targetLanguage',
            TranslateLanguage.english,
          ),
      isA<CameraTranslateState>()
          .having((s) => s.isDownloadingModel, 'isDownloadingModel', false)
          .having(
            (s) => s.targetLanguage,
            'targetLanguage',
            TranslateLanguage.vietnamese,
          ),
    ],
  );

  blocTest<CameraTranslateBloc, CameraTranslateState>(
    'scan requested emits scanning then items loaded',
    build: () {
      when(
        () => scanTranslator.scanAndTranslate(
          imagePath: any(named: 'imagePath'),
          targetLanguage: any(named: 'targetLanguage'),
        ),
      ).thenAnswer(
        (_) async => const [
          OverlayTextItem(
            originalText: 'Xin chào',
            translatedText: 'Hello',
            rect: Rect.fromLTWH(0, 0, 100, 20),
            imageSize: Size(1080, 1920),
          ),
        ],
      );

      return CameraTranslateBloc(
        scanTranslator: scanTranslator,
        historyRepository: historyRepository,
        modelManager: modelManager,
      );
    },
    act: (bloc) =>
        bloc.add(const CameraTranslateScanRequested('/tmp/test.png')),
    expect: () => [
      isA<CameraTranslateState>().having(
        (s) => s.isScanning,
        'isScanning',
        true,
      ),
      isA<CameraTranslateState>()
          .having((s) => s.isScanning, 'isScanning', false)
          .having((s) => s.items.length, 'items.length', 1),
    ],
  );

  blocTest<CameraTranslateBloc, CameraTranslateState>(
    'capture requested saves record and emits lastSavedPath',
    build: () {
      when(() => historyRepository.upsert(any())).thenAnswer((_) async {});
      return CameraTranslateBloc(
        scanTranslator: scanTranslator,
        historyRepository: historyRepository,
        modelManager: modelManager,
      );
    },
    seed: () => const CameraTranslateState(
      targetLanguage: TranslateLanguage.english,
      items: [
        OverlayTextItem(
          originalText: 'Xin chào',
          translatedText: 'Hello',
          rect: Rect.fromLTWH(0, 0, 100, 20),
          imageSize: Size(1080, 1920),
        ),
      ],
      isScanning: false,
      isCapturing: false,
      errorMessage: null,
      lastSavedPath: null,
      isDownloadingModel: false,
      downloadingLanguageLabel: null,
    ),
    act: (bloc) => bloc.add(
      const CameraTranslateCaptureRequested(savedImagePath: '/tmp/capture.png'),
    ),
    expect: () => [
      isA<CameraTranslateState>().having(
        (s) => s.isCapturing,
        'isCapturing',
        true,
      ),
      isA<CameraTranslateState>()
          .having((s) => s.isCapturing, 'isCapturing', false)
          .having((s) => s.lastSavedPath, 'lastSavedPath', '/tmp/capture.png'),
    ],
    verify: (_) {
      verify(() => historyRepository.upsert(any())).called(1);
    },
  );
}
