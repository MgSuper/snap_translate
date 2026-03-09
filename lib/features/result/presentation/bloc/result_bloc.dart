import 'dart:convert';

import 'package:camera_translator/features/history/data/scan_record.dart';
import 'package:camera_translator/features/history/repository/history_repository.dart';
import 'package:camera_translator/features/receipt/domain/receipt_parser.dart';
import 'package:camera_translator/features/receipt/domain/receipt_summary.dart';
import 'package:camera_translator/features/result/data/translated_poster_renderer.dart';
import 'package:camera_translator/features/result/presentation/bloc/result_event.dart';
import 'package:camera_translator/features/result/presentation/bloc/result_state.dart';
import 'package:camera_translator/features/scan/data/ocr_layout.dart';
import 'package:camera_translator/features/translate/data/language_id_service.dart';
import 'package:camera_translator/features/translate/data/language_lookup.dart';
import 'package:camera_translator/features/translate/data/translation_model_manager.dart';
import 'package:camera_translator/features/translate/data/translation_service.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class ResultBloc extends Bloc<ResultEvent, ResultState> {
  ResultBloc({
    required TranslationService translator,
    required TranslationModelManager modelManager,
    required HistoryRepository historyRepo,
    required String initialText,
    required LanguageIdService languageIdService,
    required List<OcrLine> layoutLines,
    required String imagePath,
    required TranslatedPosterRenderer posterRenderer,
  }) : _translator = translator,
       _modelManager = modelManager,
       _historyRepo = historyRepo,
       _languageId = languageIdService,
       _layoutLines = layoutLines,
       _imagePath = imagePath,
       _poster = posterRenderer,
       super(
         ResultIdle(
           sourceLang: TranslateLanguage.english,
           targetLang: TranslateLanguage.vietnamese,
           originalText: initialText.trim(),
           translatedText: '',
           summary: null,
         ),
       ) {
    on<ResultOriginalTextChanged>(_onTextChanged);
    on<ResultSourceLangChanged>(_onSourceChanged);
    on<ResultTargetLangChanged>(_onTargetChanged);
    on<ResultSwapLanguagesPressed>(_onSwap);
    on<ResultTranslatePressed>(_onTranslate);
    on<ResultAutoDetectRequested>(_onAutoDetect);

    // ✅ init handler to compute summary safely
    on<ResultInitRequested>(_onInit);

    // ✅ trigger init + autodetect
    add(const ResultInitRequested());
    add(const ResultAutoDetectRequested());
  }

  final TranslationService _translator;
  final TranslationModelManager _modelManager;
  final HistoryRepository _historyRepo;
  final LanguageIdService _languageId;

  final ReceiptParser _parser = ReceiptParser();
  final List<OcrLine> _layoutLines;
  final String _imagePath;
  final TranslatedPosterRenderer _poster;

  void _onTextChanged(ResultOriginalTextChanged e, Emitter<ResultState> emit) {
    emit(
      ResultIdle(
        sourceLang: state.sourceLang,
        targetLang: state.targetLang,
        originalText: e.text,
        translatedText: state.translatedText,
        summary: state.summary,
      ),
    );
  }

  void _onSourceChanged(ResultSourceLangChanged e, Emitter<ResultState> emit) {
    emit(
      ResultIdle(
        sourceLang: e.language,
        targetLang: state.targetLang,
        originalText: state.originalText,
        translatedText: state.translatedText,
        summary: state.summary,
      ),
    );
  }

  void _onTargetChanged(ResultTargetLangChanged e, Emitter<ResultState> emit) {
    emit(
      ResultIdle(
        sourceLang: state.sourceLang,
        targetLang: e.language,
        originalText: state.originalText,
        translatedText: state.translatedText,
        summary: state.summary,
      ),
    );
  }

  void _onSwap(ResultSwapLanguagesPressed e, Emitter<ResultState> emit) {
    emit(
      ResultIdle(
        sourceLang: state.targetLang,
        targetLang: state.sourceLang,
        originalText: state.originalText,
        translatedText: state.translatedText,
        summary: state.summary,
      ),
    );
  }

  Future<void> _onTranslate(
    ResultTranslatePressed event,
    Emitter<ResultState> emit,
  ) async {
    final original = state.originalText.trim();
    if (original.isEmpty) {
      emit(
        ResultFailure(
          sourceLang: state.sourceLang,
          targetLang: state.targetLang,
          originalText: state.originalText,
          translatedText: state.translatedText,
          summary: state.summary,
          message: 'Nothing to translate.',
        ),
      );
      return;
    }

    if (state.sourceLang == state.targetLang) {
      emit(
        ResultFailure(
          sourceLang: state.sourceLang,
          targetLang: state.targetLang,
          originalText: state.originalText,
          translatedText: state.translatedText,
          summary: state.summary,
          message: 'Source and target languages are the same.',
        ),
      );
      return;
    }

    emit(
      ResultDownloadingModels(
        sourceLang: state.sourceLang,
        targetLang: state.targetLang,
        originalText: state.originalText,
        translatedText: state.translatedText,
        summary: state.summary,
      ),
    );

    await _modelManager.ensureModels(
      sourceLang: state.sourceLang,
      targetLang: state.targetLang,
      wifiOnly: false,
    );

    emit(
      ResultTranslating(
        sourceLang: state.sourceLang,
        targetLang: state.targetLang,
        originalText: state.originalText,
        translatedText: state.translatedText,
        summary: state.summary,
      ),
    );

    // -------- FULL TEXT (fallback) ----------
    final translatedText = await _translator.translate(
      text: original,
      sourceLang: state.sourceLang,
      targetLang: state.targetLang,
    );

    // -------- SUMMARY TRANSLATION ----------
    ReceiptSummary? translatedSummary = state.summary;

    if (state.summary != null) {
      final items = <ReceiptItem>[];

      for (final item in state.summary!.items) {
        final translatedName = await _translator.translate(
          text: item.name,
          sourceLang: state.sourceLang,
          targetLang: state.targetLang,
        );

        items.add(
          ReceiptItem(
            name: translatedName.trim(),
            amount: item.amount, // ✅ NEVER TOUCH NUMBER
          ),
        );
      }

      MoneyLine? subtotal;
      if (state.summary!.subtotal != null) {
        final label = await _translator.translate(
          text: state.summary!.subtotal!.label,
          sourceLang: state.sourceLang,
          targetLang: state.targetLang,
        );

        subtotal = MoneyLine(
          label: label.trim(),
          amount: state.summary!.subtotal!.amount,
        );
      }

      MoneyLine? tax;
      if (state.summary!.tax != null) {
        final label = await _translator.translate(
          text: state.summary!.tax!.label,
          sourceLang: state.sourceLang,
          targetLang: state.targetLang,
        );

        tax = MoneyLine(
          label: label.trim(),
          amount: state.summary!.tax!.amount,
        );
      }

      MoneyLine? total;
      if (state.summary!.total != null) {
        final label = await _translator.translate(
          text: state.summary!.total!.label,
          sourceLang: state.sourceLang,
          targetLang: state.targetLang,
        );

        total = MoneyLine(
          label: label.trim(),
          amount: state.summary!.total!.amount,
        );
      }

      translatedSummary = ReceiptSummary(
        items: items,
        subtotal: subtotal,
        tax: tax,
        total: total,
      );
    }

    debugPrint('TRANSLATED SUMMARYYYYYYY: $translatedSummary');
    final now = DateTime.now();
    final renderedPath = await _poster.renderPng(
      originalImagePath: _imagePath,
      translatedText: translatedText.trim(),
      headerLine:
          '${codeOf(state.sourceLang).toUpperCase()} → ${codeOf(state.targetLang).toUpperCase()}',
      createdAt: now,
    );

    final record = ScanRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      sourceLang: codeOf(state.sourceLang),
      targetLang: codeOf(state.targetLang),
      originalText: original,
      translatedText: translatedText.trim(),
      summaryJson: null, // we can ignore summary for MVP B1
      originalImagePath: _imagePath,
      renderedImagePath: renderedPath,
    );

    await _historyRepo.upsert(record);

    emit(
      ResultSaved(
        sourceLang: state.sourceLang,
        targetLang: state.targetLang,
        originalText: state.originalText,
        translatedText: translatedText.trim(),
        summary: translatedSummary,
      ),
    );
  }

  Future<void> _onAutoDetect(
    ResultAutoDetectRequested event,
    Emitter<ResultState> emit,
  ) async {
    try {
      final code = await _languageId.detectLanguageCode(state.originalText);
      if (code == null) return;

      final detected = translateLanguageFromCode(code);
      if (detected == null) return;

      // UX rule:
      // - source = detected
      // - if detected != English => target defaults to English
      // - if detected == English => target defaults to Vietnamese (you can change later)
      final defaultTarget = detected == TranslateLanguage.english
          ? TranslateLanguage.vietnamese
          : TranslateLanguage.english;

      emit(
        ResultIdle(
          sourceLang: detected,
          targetLang: defaultTarget,
          originalText: state.originalText,
          translatedText: state.translatedText,
          summary: state.summary,
        ),
      );
    } catch (_) {
      // ignore auto-detect errors silently (don’t block user)
    }
  }

  Future<void> _onInit(
    ResultInitRequested event,
    Emitter<ResultState> emit,
  ) async {
    print('[DEBUG] layoutLines count = ${_layoutLines.length}');
    final summary = _parser.parse(_layoutLines);
    print('[DEBUG] parsed items = ${summary.items.length}');

    emit(
      ResultIdle(
        sourceLang: state.sourceLang,
        targetLang: state.targetLang,
        originalText: state.originalText,
        translatedText: state.translatedText,
        summary: summary,
      ),
    );
  }
}

Map<String, dynamic> _summaryToJson(ReceiptSummary summary) {
  return {
    'items': summary.items
        .map((e) => {'name': e.name, 'amount': e.amount})
        .toList(),
    'subtotal': summary.subtotal == null
        ? null
        : {
            'label': summary.subtotal!.label,
            'amount': summary.subtotal!.amount,
          },
    'tax': summary.tax == null
        ? null
        : {'label': summary.tax!.label, 'amount': summary.tax!.amount},
    'total': summary.total == null
        ? null
        : {'label': summary.total!.label, 'amount': summary.total!.amount},
  };
}
