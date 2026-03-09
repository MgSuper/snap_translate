import 'package:hive_ce/hive.dart';

part 'scan_record.g.dart';

@HiveType(typeId: 1)
class ScanRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final String sourceLang;

  @HiveField(3)
  final String targetLang;

  @HiveField(4)
  final String originalText;

  @HiveField(5)
  final String translatedText;

  @HiveField(6)
  final String? summaryJson;

  // ✅ NEW: original receipt photo path
  @HiveField(7)
  final String? originalImagePath;

  // ✅ NEW: generated PNG poster path (receipt + translated text)
  @HiveField(8)
  final String? renderedImagePath;

  ScanRecord({
    required this.id,
    required this.createdAt,
    required this.sourceLang,
    required this.targetLang,
    required this.originalText,
    required this.translatedText,
    required this.summaryJson,
    required this.originalImagePath,
    required this.renderedImagePath,
  });
}
