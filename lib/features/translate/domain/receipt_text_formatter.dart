class ReceiptTextFormatter {
  static String format(String input) {
    var s = input.trim();
    if (s.isEmpty) return s;

    // Normalize whitespace
    s = s.replaceAll('\r\n', '\n');
    s = s.replaceAll(RegExp(r'[ \t]+'), ' ');

    // Ensure newline after common separators
    s = s.replaceAll(RegExp(r'\s*-\s*'), ' - ');
    s = s.replaceAll(RegExp(r'\s*:\s*'), ': ');

    // Break very long lines (simple wrap)
    final lines = s.split('\n').expand((line) => _wrapLine(line, 64)).toList();

    // Add spacing between “sections” (heuristics)
    final out = <String>[];
    for (final line in lines) {
      final l = line.trim();
      if (l.isEmpty) continue;

      // Insert blank line before key receipt markers
      final lower = l.toLowerCase();
      final isMarker =
          lower.contains('total') ||
          lower.contains('subtotal') ||
          lower.contains('tax') ||
          lower.contains('cash') ||
          lower.contains('change');

      if (isMarker && out.isNotEmpty && out.last.isNotEmpty) {
        out.add('');
      }
      out.add(l);
    }

    return out.join('\n');
  }

  static Iterable<String> _wrapLine(String line, int maxLen) sync* {
    var s = line.trim();
    if (s.length <= maxLen) {
      yield s;
      return;
    }

    while (s.length > maxLen) {
      final cut = s.lastIndexOf(' ', maxLen);
      if (cut <= 0) break;
      yield s.substring(0, cut).trim();
      s = s.substring(cut + 1).trim();
    }
    if (s.isNotEmpty) yield s;
  }
}
