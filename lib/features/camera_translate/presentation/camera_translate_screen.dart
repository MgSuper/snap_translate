import 'dart:async';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera_translator/app/router.dart';
import 'package:camera_translator/features/camera_translate/data/camera_scan_translator_service.dart';
import 'package:camera_translator/features/camera_translate/data/camera_translate_model_manager.dart';
import 'package:camera_translator/features/camera_translate/presentation/bloc/camera_translate_bloc.dart';
import 'package:camera_translator/features/camera_translate/presentation/bloc/camera_translate_event.dart';
import 'package:camera_translator/features/camera_translate/presentation/bloc/camera_translate_state.dart';
import 'package:camera_translator/features/translate/data/supported_languages.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:camera_translator/app/core/di/di.dart';
import 'package:camera_translator/features/history/data/scan_record.dart';
import 'package:camera_translator/features/history/repository/history_repository.dart';

import 'package:camera/camera.dart';
import 'package:camera_translator/features/translate/data/language_lookup.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import 'overlay_text_item.dart';

class CameraTranslateScreen extends StatelessWidget {
  const CameraTranslateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CameraTranslateBloc(
        scanTranslator: getIt<CameraScanTranslatorService>(),
        historyRepository: getIt<HistoryRepository>(),
        modelManager: getIt<CameraTranslateModelManager>(),
      ),
      child: const _CameraTranslateView(),
    );
  }
}

class _CameraTranslateView extends StatefulWidget {
  const _CameraTranslateView();

  @override
  State<_CameraTranslateView> createState() => _CameraTranslateViewState();
}

class _CameraTranslateViewState extends State<_CameraTranslateView> {
  CameraController? _controller;

  late final CameraScanTranslatorService _scanTranslator;

  Timer? _scanTimer;
  bool _isScanning = false;

  final GlobalKey _captureKey = GlobalKey();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _scanTranslator = getIt<CameraScanTranslatorService>();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();

    if (!mounted) return;

    setState(() {});
    _startScanning();
  }

  void _startScanning() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _scanFrame(),
    );
  }

  Future<void> _scanFrame() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isTakingPicture) return;

    final bloc = context.read<CameraTranslateBloc>();

    if (bloc.state.isScanning) return;
    if (bloc.state.isDownloadingModel) return;

    try {
      final file = await controller.takePicture();
      if (!mounted) return;

      context.read<CameraTranslateBloc>().add(
        CameraTranslateScanRequested(file.path),
      );
    } catch (e) {
      debugPrint('Camera translate scan error: $e');
    }
  }

  Future<void> _captureOverlayImage() async {
    final bloc = context.read<CameraTranslateBloc>();
    if (bloc.state.isCapturing) return;

    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw StateError('Capture boundary not found');
      }

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw StateError('Failed to convert image to PNG bytes');
      }

      final dir = await getApplicationDocumentsDirectory();
      final captureDir = Directory(
        p.join(dir.path, 'camera_translate_captures'),
      );
      if (!captureDir.existsSync()) {
        captureDir.createSync(recursive: true);
      }

      final now = DateTime.now();

      final filePath = p.join(
        captureDir.path,
        'capture_${now.microsecondsSinceEpoch}.png',
      );

      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      context.read<CameraTranslateBloc>().add(
        CameraTranslateCaptureRequested(savedImagePath: filePath),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  Rect _mapRectToPreview({
    required Rect imageRect,
    required Size imageSize,
    required Size previewSize,
  }) {
    final imageAspect = imageSize.width / imageSize.height;
    final previewAspect = previewSize.width / previewSize.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (previewAspect > imageAspect) {
      // Preview is wider relative to image, so image is scaled by width
      scale = previewSize.width / imageSize.width;
      final scaledHeight = imageSize.height * scale;
      offsetY = (previewSize.height - scaledHeight) / 2;
    } else {
      // Preview is taller relative to image, so image is scaled by height
      scale = previewSize.height / imageSize.height;
      final scaledWidth = imageSize.width * scale;
      offsetX = (previewSize.width - scaledWidth) / 2;
    }

    return Rect.fromLTWH(
      imageRect.left * scale + offsetX,
      imageRect.top * scale + offsetY,
      imageRect.width * scale,
      imageRect.height * scale,
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _controller?.dispose();
    _scanTranslator.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final blocState = context.watch<CameraTranslateBloc>().state;

    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocListener<CameraTranslateBloc, CameraTranslateState>(
      listenWhen: (previous, current) =>
          previous.lastSavedPath != current.lastSavedPath ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.lastSavedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Captured image saved to history'),
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  context.push(AppRoutes.history);
                },
              ),
            ),
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Camera Translate'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TranslateLanguage>(
                    value: blocState.targetLanguage,
                    items: supportedLanguages
                        .map(
                          (lang) => DropdownMenuItem<TranslateLanguage>(
                            value: lang.language,
                            child: Text(lang.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: blocState.isDownloadingModel
                        ? null
                        : (value) {
                            if (value == null) return;
                            context.read<CameraTranslateBloc>().add(
                              CameraTranslateTargetLanguageChanged(value),
                            );
                          },
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            RepaintBoundary(
              key: _captureKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final previewSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return Stack(
                    children: [
                      Positioned.fill(child: CameraPreview(controller)),

                      ...blocState.items.map((item) {
                        final mapped = _mapRectToPreview(
                          imageRect: item.rect,
                          imageSize: item.imageSize,
                          previewSize: previewSize,
                        );
                        final bubbleWidth = mapped.width.clamp(80.0, 320.0);

                        return Positioned(
                          left: mapped.left,
                          top: mapped.top,
                          width: bubbleWidth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              item.translatedText,
                              softWrap: true,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),

            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        blocState.isDownloadingModel
                            ? 'Downloading ${blocState.downloadingLanguageLabel ?? ''} language pack... Wi-Fi recommended'
                            : blocState.isScanning
                            ? 'Scanning and translating...'
                            : 'Point camera at text',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: blocState.isDownloadingModel
                        ? null
                        : blocState.isCapturing
                        ? null
                        : _captureOverlayImage,
                    icon: _isCapturing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(_isCapturing ? 'Saving...' : 'Capture'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
