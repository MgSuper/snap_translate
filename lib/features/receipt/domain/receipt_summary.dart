class ReceiptSummary {
  const ReceiptSummary({
    required this.items,
    this.subtotal,
    this.tax,
    this.total,
  });

  final List<ReceiptItem> items;
  final MoneyLine? subtotal;
  final MoneyLine? tax;
  final MoneyLine? total;
}

class ReceiptItem {
  const ReceiptItem({required this.name, required this.amount});

  final String name;
  final String amount;
}

class MoneyLine {
  const MoneyLine({required this.label, required this.amount});

  final String label;
  final String amount;
}
