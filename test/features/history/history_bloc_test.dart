import 'package:bloc_test/bloc_test.dart';
import 'package:camera_translator/features/history/data/scan_record.dart';
import 'package:camera_translator/features/history/presentation/bloc/history_bloc.dart';
import 'package:camera_translator/features/history/presentation/bloc/history_event.dart';
import 'package:camera_translator/features/history/presentation/bloc/history_state.dart';
import 'package:camera_translator/features/history/repository/history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:mocktail/mocktail.dart';

class _MockHistoryRepo extends Mock implements HistoryRepository {}

void main() {
  late HistoryRepository repo;

  setUp(() {
    repo = _MockHistoryRepo();
  });

  blocTest<HistoryBloc, HistoryState>(
    'emits [Loading, Empty] when repo returns empty list',
    build: () {
      when(() => repo.getAll()).thenAnswer((_) async => []);
      return HistoryBloc(repo);
    },
    act: (bloc) => bloc.add(const HistoryLoadRequested()),
    expect: () => const [HistoryLoading(), HistoryEmpty()],
  );

  blocTest<HistoryBloc, HistoryState>(
    'emits [Loading, Loaded] when repo returns items',
    build: () {
      when(() => repo.getAll()).thenAnswer(
        (_) async => [
          ScanRecord(
            id: '1',
            createdAt: DateTime(2026, 2, 27),
            sourceLang: 'en',
            targetLang: 'vi',
            originalText: 'a',
            translatedText: 'b',
          ),
        ],
      );
      return HistoryBloc(repo);
    },
    act: (bloc) => bloc.add(const HistoryLoadRequested()),
    expect: () => [const HistoryLoading(), isA<HistoryLoaded>()],
    verify: (_) => verify(() => repo.getAll()).called(1),
  );
}
