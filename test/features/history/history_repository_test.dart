import 'dart:io';

import 'package:camera_translator/features/history/data/history_box.dart';
import 'package:camera_translator/features/history/data/scan_record.dart';
import 'package:camera_translator/features/history/repository/history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Create a temp directory for Hive storage
    tempDir = await Directory.systemTemp.createTemp('hive_ce_test_');

    // Initialize Hive with a path
    Hive.init(tempDir.path);

    // Register adapter ONLY ONCE
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ScanRecordAdapter());
    }

    // Open box once for this test file
    if (!Hive.isBoxOpen(HistoryBox.boxName)) {
      await Hive.openBox<ScanRecord>(HistoryBox.boxName);
    }
  });

  tearDownAll(() async {
    if (Hive.isBoxOpen(HistoryBox.boxName)) {
      await Hive.box<ScanRecord>(HistoryBox.boxName).close();
    }
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    // Clear box between tests
    await Hive.box<ScanRecord>(HistoryBox.boxName).clear();
  });

  test('upsert then getAll returns item', () async {
    final repo = HistoryRepository();
    final now = DateTime(2026, 2, 27);

    await repo.upsert(
      ScanRecord(
        id: '1',
        createdAt: now,
        sourceLang: 'en',
        targetLang: 'vi',
        originalText: 'Total 100',
        translatedText: 'Tổng 100',
      ),
    );

    final items = await repo.getAll();

    expect(items.length, 1);
    expect(items.first.id, '1');
    expect(items.first.originalText, 'Total 100');
  });

  test('getAll returns sorted by createdAt desc', () async {
    final repo = HistoryRepository();

    await repo.upsert(
      ScanRecord(
        id: 'old',
        createdAt: DateTime(2026, 1, 1),
        sourceLang: 'en',
        targetLang: 'vi',
        originalText: 'old',
        translatedText: 'old',
      ),
    );

    await repo.upsert(
      ScanRecord(
        id: 'new',
        createdAt: DateTime(2026, 2, 1),
        sourceLang: 'en',
        targetLang: 'vi',
        originalText: 'new',
        translatedText: 'new',
      ),
    );

    final items = await repo.getAll();
    expect(items.first.id, 'new');
    expect(items.last.id, 'old');
  });
}
