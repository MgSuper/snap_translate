import 'package:camera_translator/features/scan/data/ocr_service.dart';
import 'package:camera_translator/features/scan/presentation/bloc/scan_event.dart';
import 'package:camera_translator/features/scan/presentation/bloc/scan_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc(this._ocr) : super(const ScanIdle()) {
    on<ScanOcrRequested>(_onOcrRequested);
    on<ScanResetRequested>((event, emit) => emit(const ScanIdle()));
  }

  final OcrService _ocr;

  Future<void> _onOcrRequested(
    ScanOcrRequested event,
    Emitter<ScanState> emit,
  ) async {
    emit(const ScanProcessing());
    try {
      final layout = await _ocr.recognizeText(event.imagePath);
      final text = layout.fullText.trim();

      if (text.isEmpty) {
        emit(
          const ScanFailure(
            'No text detected. Try again with better lighting.',
          ),
        );
        return;
      }

      emit(ScanSuccess(imagePath: event.imagePath, layout: layout));
    } catch (e) {
      emit(ScanFailure(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _ocr.dispose();
    return super.close();
  }
}
