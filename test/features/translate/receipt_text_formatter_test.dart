import 'package:flutter_test/flutter_test.dart';
import 'package:camera_translator/features/translate/domain/receipt_text_formatter.dart';

void main() {
  test('formats by trimming and wrapping long lines', () {
    final input =
        '   hello     world   \n'
        'this is a very very very very very very very very long line that should wrap   ';
    final out = ReceiptTextFormatter.format(input);

    expect(out.startsWith('hello world'), true);
    expect(out.contains('\n'), true); // wrapped
  });

  test('adds spacing before total markers', () {
    final input = 'item 1\nitem 2\ntotal 100000';
    final out = ReceiptTextFormatter.format(input);

    expect(out.contains('\n\ntotal'), true);
  });
}
