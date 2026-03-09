import 'package:camera_translator/features/camera_translate/data/camera_scan_translator_service.dart';
import 'package:camera_translator/features/camera_translate/data/camera_translate_model_manager.dart';
import 'package:camera_translator/features/camera_translate/presentation/bloc/camera_translate_event.dart';
import 'package:camera_translator/features/camera_translate/presentation/bloc/camera_translate_state.dart';
import 'package:camera_translator/features/history/data/scan_record.dart';
import 'package:camera_translator/features/history/repository/history_repository.dart';
import 'package:camera_translator/features/translate/data/language_lookup.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CameraTranslateBloc
    extends Bloc<CameraTranslateEvent, CameraTranslateState> {
  CameraTranslateBloc({
    required CameraScanTranslatorService scanTranslator,
    required HistoryRepository historyRepository,
    required CameraTranslateModelManager modelManager,
  }) : _scanTranslator = scanTranslator,
       _historyRepository = historyRepository,
       _modelManager = modelManager,
       super(CameraTranslateState.initial()) {
    on<CameraTranslateTargetLanguageChanged>(_onTargetLanguageChanged);
    on<CameraTranslateScanRequested>(_onScanRequested);
    on<CameraTranslateCaptureRequested>(_onCaptureRequested);
    on<CameraTranslateClearRequested>(_onClearRequested);
  }

  final CameraScanTranslatorService _scanTranslator;
  final HistoryRepository _historyRepository;
  final CameraTranslateModelManager _modelManager;

  Future<void> _onTargetLanguageChanged(
    CameraTranslateTargetLanguageChanged event,
    Emitter<CameraTranslateState> emit,
  ) async {
    emit(
      state.copyWith(
        isDownloadingModel: true,
        downloadingLanguageLabel: codeOf(event.language).toUpperCase(),
        clearError: true,
      ),
    );

    try {
      await _modelManager.ensureTargetModelReady(event.language);

      emit(
        state.copyWith(
          targetLanguage: event.language,
          isDownloadingModel: false,
          clearDownloadingLanguageLabel: true,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isDownloadingModel: false,
          clearDownloadingLanguageLabel: true,
          errorMessage:
              'Language pack download failed or timed out. Try Wi-Fi.',
        ),
      );
    }
  }

  Future<void> _onScanRequested(
    CameraTranslateScanRequested event,
    Emitter<CameraTranslateState> emit,
  ) async {
    if (state.isScanning) return;

    emit(state.copyWith(isScanning: true, clearError: true));

    try {
      final overlays = await _scanTranslator.scanAndTranslate(
        imagePath: event.imagePath,
        targetLanguage: state.targetLanguage,
      );

      emit(
        state.copyWith(isScanning: false, items: overlays, clearError: true),
      );
    } catch (e) {
      emit(state.copyWith(isScanning: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onCaptureRequested(
    CameraTranslateCaptureRequested event,
    Emitter<CameraTranslateState> emit,
  ) async {
    if (state.isCapturing) return;

    emit(
      state.copyWith(
        isCapturing: true,
        clearError: true,
        clearLastSavedPath: true,
      ),
    );

    try {
      final now = DateTime.now();

      final originalText = state.items.map((e) => e.originalText).join('\n');
      final translatedText = state.items
          .map((e) => e.translatedText)
          .join('\n');

      final record = ScanRecord(
        id: now.microsecondsSinceEpoch.toString(),
        createdAt: now,
        sourceLang: 'auto',
        targetLang: codeOf(state.targetLanguage),
        originalText: originalText,
        translatedText: translatedText,
        summaryJson: null,
        originalImagePath: event.savedImagePath,
        renderedImagePath: event.savedImagePath,
      );

      await _historyRepository.upsert(record);

      emit(
        state.copyWith(
          isCapturing: false,
          lastSavedPath: event.savedImagePath,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isCapturing: false, errorMessage: e.toString()));
    }
  }

  void _onClearRequested(
    CameraTranslateClearRequested event,
    Emitter<CameraTranslateState> emit,
  ) {
    emit(
      state.copyWith(
        items: const [],
        clearError: true,
        clearLastSavedPath: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _scanTranslator.close();
    return super.close();
  }
}
