import 'package:camera_translator/features/history/presentation/bloc/history_event.dart';
import 'package:camera_translator/features/history/presentation/bloc/history_state.dart';
import 'package:camera_translator/features/history/repository/history_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc(this._repo) : super(const HistoryLoading()) {
    on<HistoryLoadRequested>(_onLoad);
    on<HistoryDeleteRequested>(_onDelete);
    on<HistoryClearRequested>(_onClear);
  }

  final HistoryRepository _repo;

  Future<void> _onLoad(
    HistoryLoadRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());
    try {
      final items = await _repo.getAll();
      if (items.isEmpty) {
        emit(const HistoryEmpty());
      } else {
        emit(HistoryLoaded(items));
      }
    } catch (e) {
      emit(HistoryFailure(e.toString()));
    }
  }

  Future<void> _onDelete(
    HistoryDeleteRequested event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _repo.deleteById(event.id);
      add(const HistoryLoadRequested());
    } catch (e) {
      emit(HistoryFailure(e.toString()));
    }
  }

  Future<void> _onClear(
    HistoryClearRequested event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _repo.clearAll();
      add(const HistoryLoadRequested());
    } catch (e) {
      emit(HistoryFailure(e.toString()));
    }
  }
}
