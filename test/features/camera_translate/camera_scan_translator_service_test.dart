import 'package:camera_translator/features/camera_translate/data/camera_scan_translator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cleanBlockText', () {
    test('normalizes whitespace and newlines', () {
      final result = cleanBlockText('Hello \n   world   test');
      expect(result, 'Hello world test');
    });
  });

  group('shouldTranslateBlock', () {
    test('returns false for empty text', () {
      expect(shouldTranslateBlock(''), false);
    });

    test('returns false for very short text', () {
      expect(shouldTranslateBlock('Hi'), false);
    });

    test('returns false for digits only', () {
      expect(shouldTranslateBlock('123456'), false);
    });

    test('returns false for punctuation only', () {
      expect(shouldTranslateBlock('...'), false);
    });

    test('returns false for mostly digits', () {
      expect(shouldTranslateBlock('A1 2 3 4 5'), false);
    });

    test('returns true for normal phrase', () {
      expect(shouldTranslateBlock('Xin chào hân hạnh được gặp bạn'), true);
    });

    test('returns true for English phrase', () {
      expect(shouldTranslateBlock('Hello pleased to meet you'), true);
    });
  });
}
