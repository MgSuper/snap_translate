import 'package:camera/camera.dart';
import 'package:camera_translator/app/router.dart';
import 'package:camera_translator/features/result/result_args.dart';
import 'package:camera_translator/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:camera_translator/features/scan/presentation/bloc/scan_event.dart';
import 'package:camera_translator/features/scan/presentation/bloc/scan_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitializing = true;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _cameraError = null;
    });

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _isInitializing = false;
        _cameraError = 'Camera permission denied.';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _cameraError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _captureAndOcr() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final scanBloc = context.read<ScanBloc>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final file = await controller.takePicture();
      scanBloc.add(ScanOcrRequested(file.path));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: BlocListener<ScanBloc, ScanState>(
        listener: (context, state) async {
          if (state is ScanSuccess) {
            // Temporary: show OCR result in a bottom sheet.
            // Step 4 will route to Result screen with translation UI.
            if (!mounted) return;
            context.push(
              AppRoutes.result,
              extra: ResultArgs(
                imagePath: state.imagePath,
                layout: state.layout,
              ),
            );
          } else if (state is ScanFailure) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: _isInitializing
            ? const Center(child: CircularProgressIndicator())
            : (_cameraError != null)
            ? _CameraErrorView(message: _cameraError!, onRetry: _initCamera)
            : Column(
                children: [
                  Expanded(
                    child: controller == null
                        ? const SizedBox.shrink()
                        : CameraPreview(controller),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BlocBuilder<ScanBloc, ScanState>(
                        builder: (context, state) {
                          final isBusy = state is ScanProcessing;
                          return SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: isBusy ? null : _captureAndOcr,
                              icon: isBusy
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt),
                              label: Text(
                                isBusy ? 'Recognizing...' : 'Capture',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OcrResultSheet extends StatelessWidget {
  const _OcrResultSheet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text('OCR Result', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SelectableText(text),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 42,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
