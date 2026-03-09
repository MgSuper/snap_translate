import '../../scan/data/ocr_layout.dart';
import 'receipt_summary.dart';

class ReceiptParser {
  static final _moneyRegex = RegExp(
    r'\d{1,3}(?:[.,]\d{3})+|\d+',
  ); // 118,000 or 146000

  static final _totalKeywords = [
    'total',
    'subtotal',
    'vat',
    'tax',
    'tổng',
    'tạm tính',
    'thuế',
  ];

  ReceiptSummary parse(List<OcrLine> lines) {
    if (lines.isEmpty) {
      return const ReceiptSummary(items: []);
    }

    final rows = _groupByRow(lines);

    final items = <ReceiptItem>[];
    MoneyLine? subtotal;
    MoneyLine? tax;
    MoneyLine? total;

    for (final row in rows) {
      final rowText = row.map((e) => e.text).join(' ').trim();
      if (rowText.isEmpty) continue;

      final matches = _moneyRegex.allMatches(rowText).toList();
      if (matches.isEmpty) continue;

      // Use the RIGHTMOST number as the amount
      final lastMatch = matches.last;
      final amount = lastMatch.group(0)!;

      final label = rowText.substring(0, lastMatch.start).trim();
      final lower = label.toLowerCase();

      if (label.isEmpty) continue;

      if (_containsKeyword(lower, 'subtotal')) {
        subtotal = MoneyLine(label: label, amount: amount);
        continue;
      }

      if (_containsKeyword(lower, 'vat') ||
          _containsKeyword(lower, 'tax') ||
          _containsKeyword(lower, 'thuế')) {
        tax = MoneyLine(label: label, amount: amount);
        continue;
      }

      if (_containsKeyword(lower, 'total') || _containsKeyword(lower, 'tổng')) {
        total = MoneyLine(label: label, amount: amount);
        continue;
      }

      // Otherwise treat as item row
      items.add(ReceiptItem(name: label, amount: amount));
    }

    return ReceiptSummary(
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
    );
  }

  List<List<OcrLine>> _groupByRow(List<OcrLine> lines) {
    final sorted = [...lines]..sort((a, b) => a.centerY.compareTo(b.centerY));

    final rows = <List<OcrLine>>[];

    const threshold = 10.0; // pixel grouping tolerance

    for (final line in sorted) {
      if (rows.isEmpty) {
        rows.add([line]);
        continue;
      }

      final lastRow = rows.last;
      final avgY =
          lastRow.map((e) => e.centerY).reduce((a, b) => a + b) /
          lastRow.length;

      if ((line.centerY - avgY).abs() < threshold) {
        lastRow.add(line);
      } else {
        rows.add([line]);
      }
    }

    return rows;
  }

  bool _containsKeyword(String text, String keyword) {
    return text.contains(keyword);
  }
}
