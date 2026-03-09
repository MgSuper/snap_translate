import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

abstract interface class LanguageIdService {
  Future<String?> detectLanguageCode(String text);
  Future<void> dispose();
}

class MlKitLanguageIdService implements LanguageIdService {
  MlKitLanguageIdService({double confidenceThreshold = 0.5})
    : _identifier = LanguageIdentifier(
        confidenceThreshold: confidenceThreshold,
      );

  final LanguageIdentifier _identifier;

  @override
  Future<String?> detectLanguageCode(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return null;

    final code = await _identifier.identifyLanguage(cleaned);
    if (code == 'und') return null; // undetermined
    return code; // e.g. 'vi', 'en'
  }

  @override
  Future<void> dispose() => _identifier.close();
}
