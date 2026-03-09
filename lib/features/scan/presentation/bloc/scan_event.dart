sealed class ScanEvent {
  const ScanEvent();
}

final class ScanOcrRequested extends ScanEvent {
  const ScanOcrRequested(this.imagePath);
  final String imagePath;
}

final class ScanResetRequested extends ScanEvent {
  const ScanResetRequested();
}
