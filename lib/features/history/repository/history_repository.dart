import 'package:camera_translator/features/history/data/history_box.dart';
import 'package:camera_translator/features/history/data/scan_record.dart';

class HistoryRepository {
  Future<List<ScanRecord>> getAll() async {
    final values = HistoryBox.box.values.toList(growable: false);
    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  Future<void> upsert(ScanRecord record) async {
    await HistoryBox.box.put(record.id, record);
  }

  Future<void> deleteById(String id) async {
    await HistoryBox.box.delete(id);
  }

  Future<void> clearAll() async {
    await HistoryBox.box.clear();
  }
}
