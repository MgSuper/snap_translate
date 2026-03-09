sealed class HistoryEvent {
  const HistoryEvent();
}

final class HistoryLoadRequested extends HistoryEvent {
  const HistoryLoadRequested();
}

final class HistoryDeleteRequested extends HistoryEvent {
  const HistoryDeleteRequested(this.id);
  final String id;
}

final class HistoryClearRequested extends HistoryEvent {
  const HistoryClearRequested();
}
