import 'package:camera_translator/features/camera_translate/presentation/overlay_text_item.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class CameraTranslateState {
  const CameraTranslateState({
    required this.targetLanguage,
    required this.items,
    required this.isScanning,
    required this.isCapturing,
    required this.errorMessage,
    required this.lastSavedPath,
    required this.isDownloadingModel,
    required this.downloadingLanguageLabel,
  });

  factory CameraTranslateState.initial() {
    return const CameraTranslateState(
      targetLanguage: TranslateLanguage.english,
      items: [],
      isScanning: false,
      isCapturing: false,
      isDownloadingModel: false,
      downloadingLanguageLabel: null,
      errorMessage: null,
      lastSavedPath: null,
    );
  }

  final TranslateLanguage targetLanguage;
  final List<OverlayTextItem> items;
  final bool isScanning;
  final bool isCapturing;
  final String? errorMessage;
  final String? lastSavedPath;
  final bool isDownloadingModel;
  final String? downloadingLanguageLabel;

  CameraTranslateState copyWith({
    TranslateLanguage? targetLanguage,
    List<OverlayTextItem>? items,
    bool? isScanning,
    bool? isCapturing,
    String? errorMessage,
    String? lastSavedPath,
    bool clearError = false,
    bool clearLastSavedPath = false,
    bool? isDownloadingModel,
    String? downloadingLanguageLabel,
    bool clearDownloadingLanguageLabel = false,
  }) {
    return CameraTranslateState(
      targetLanguage: targetLanguage ?? this.targetLanguage,
      items: items ?? this.items,
      isScanning: isScanning ?? this.isScanning,
      isCapturing: isCapturing ?? this.isCapturing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSavedPath: clearLastSavedPath
          ? null
          : (lastSavedPath ?? this.lastSavedPath),
      isDownloadingModel: isDownloadingModel ?? this.isDownloadingModel,
      downloadingLanguageLabel: clearDownloadingLanguageLabel
          ? null
          : (downloadingLanguageLabel ?? this.downloadingLanguageLabel),
    );
  }
}
