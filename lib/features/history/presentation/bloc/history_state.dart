import 'package:camera_translator/features/history/data/scan_record.dart';

sealed class HistoryState {
  const HistoryState();
}

final class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

final class HistoryLoaded extends HistoryState {
  const HistoryLoaded(this.items);
  final List<ScanRecord> items;
}

final class HistoryEmpty extends HistoryState {
  const HistoryEmpty();
}

final class HistoryFailure extends HistoryState {
  const HistoryFailure(this.message);
  final String message;
}
