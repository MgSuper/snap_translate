import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:camera_translator/features/scan/data/ocr_layout.dart';
import 'package:camera_translator/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:camera_translator/features/scan/presentation/bloc/scan_event.dart';
import 'package:camera_translator/features/scan/presentation/bloc/scan_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:camera_translator/features/scan/data/ocr_service.dart';

class _MockOcrService extends Mock implements OcrService {}

void main() {
  late OcrService ocr;

  setUp(() {
    ocr = _MockOcrService();
  });

  blocTest<ScanBloc, ScanState>(
    'emits [Processing, Success] when OCR returns text',
    build: () {
      when(() => ocr.recognizeText(any())).thenAnswer(
        (_) async => OcrLayout(
          fullText: 'hello',
          lines: const [
            OcrLine(text: 'hello', rect: Rect.fromLTWH(0, 0, 10, 10)),
          ],
        ),
      );
      when(() => ocr.dispose()).thenAnswer((_) async {});
      return ScanBloc(ocr);
    },
    act: (bloc) => bloc.add(const ScanOcrRequested('/tmp/a.jpg')),
    expect: () => [
      const ScanProcessing(),
      isA<ScanSuccess>()
          .having((s) => s.layout.fullText, 'layout fullText', 'hello')
          .having((s) => s.imagePath, 'imagePath', '/tmp/a.jpg'),
    ],
    verify: (_) => verify(() => ocr.recognizeText('/tmp/a.jpg')).called(1),
  );

  blocTest<ScanBloc, ScanState>(
    'emits [Processing, Failure] when OCR returns empty',
    build: () {
      when(() => ocr.recognizeText(any())).thenAnswer(
        (_) async => OcrLayout(
          fullText: '',
          lines: const [OcrLine(text: '', rect: Rect.fromLTWH(0, 0, 0, 0))],
        ),
      );
      when(() => ocr.dispose()).thenAnswer((_) async {});
      return ScanBloc(ocr);
    },
    act: (bloc) => bloc.add(const ScanOcrRequested('/tmp/a.jpg')),
    expect: () => const [
      ScanProcessing(),
      ScanFailure('No text detected. Try again with better lighting.'),
    ],
  );

  blocTest<ScanBloc, ScanState>(
    'emits [Processing, Failure] when OCR throws',
    build: () {
      when(() => ocr.recognizeText(any())).thenThrow(Exception('boom'));
      when(() => ocr.dispose()).thenAnswer((_) async {});
      return ScanBloc(ocr);
    },
    act: (bloc) => bloc.add(const ScanOcrRequested('/tmp/a.jpg')),
    expect: () => [
      const ScanProcessing(),
      isA<ScanFailure>().having((s) => s.message, 'message', contains('boom')),
    ],
  );
}
