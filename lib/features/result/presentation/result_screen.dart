import 'package:camera_translator/app/router.dart';
import 'package:camera_translator/features/receipt/domain/receipt_summary.dart';
import 'package:camera_translator/features/result/presentation/bloc/result_bloc.dart';
import 'package:camera_translator/features/result/presentation/bloc/result_event.dart';
import 'package:camera_translator/features/result/presentation/bloc/result_state.dart';
import 'package:camera_translator/features/result/result_args.dart';
import 'package:camera_translator/features/translate/data/supported_languages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.args});

  final ResultArgs args;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.args.layout.fullText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ResultBloc, ResultState>(
      listener: (context, state) {
        if (state is ResultSaved) {
          final snack = SnackBar(
            content: const Text('Saved to Scan History'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => context.push(AppRoutes.history),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snack);
        } else if (state is ResultFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Result'),
          actions: [
            IconButton(
              tooltip: 'History',
              onPressed: () => context.push(AppRoutes.history),
              icon: const Icon(Icons.history),
            ),
          ],
        ),
        body: BlocBuilder<ResultBloc, ResultState>(
          builder: (context, state) {
            // Keep text controller in sync if bloc changes it externally.
            if (_controller.text != state.originalText) {
              _controller.value = _controller.value.copyWith(
                text: state.originalText,
                selection: TextSelection.collapsed(
                  offset: state.originalText.length,
                ),
              );
            }

            final isDownloading = state is ResultDownloadingModels;
            final isTranslating = state is ResultTranslating;
            final busy = isDownloading || isTranslating;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Top dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: _LangDropdown(
                          label: 'From',
                          value: state.sourceLang,
                          onChanged: busy
                              ? null
                              : (v) => context.read<ResultBloc>().add(
                                  ResultSourceLangChanged(v!),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: busy
                            ? null
                            : () => context.read<ResultBloc>().add(
                                const ResultSwapLanguagesPressed(),
                              ),
                        icon: const Icon(Icons.swap_horiz),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LangDropdown(
                          label: 'To',
                          value: state.targetLang,
                          onChanged: busy
                              ? null
                              : (v) => context.read<ResultBloc>().add(
                                  ResultTargetLangChanged(v!),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // _ReceiptSummarySection(summary: state.summary), // <- add this
                  // const SizedBox(height: 14),
                  Expanded(
                    child: ListView(
                      children: [
                        Text(
                          'Original',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controller,
                          maxLines: 6,
                          onChanged: (v) => context.read<ResultBloc>().add(
                            ResultOriginalTextChanged(v),
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'OCR text…',
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: busy
                                    ? null
                                    : () => context.read<ResultBloc>().add(
                                        const ResultTranslatePressed(),
                                      ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (busy) ...[
                                      const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Text(
                                      isDownloading
                                          ? 'Downloading…'
                                          : isTranslating
                                          ? 'Translating…'
                                          : 'Translate & Save',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        Text(
                          'Translated',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(
                            state.translatedText.isEmpty
                                ? '—'
                                : state.translatedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LangDropdown extends StatelessWidget {
  const _LangDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TranslateLanguage value;
  final ValueChanged<TranslateLanguage?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TranslateLanguage>(
          value: value,
          isExpanded: true,
          items: supportedLanguages
              .map(
                (l) =>
                    DropdownMenuItem(value: l.language, child: Text(l.label)),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ReceiptSummarySection extends StatelessWidget {
  const _ReceiptSummarySection({required this.summary});

  final ReceiptSummary? summary; // you'll add this model

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Receipt Summary will appear here after we parse OCR layout.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          // ITEMS
          ...summary!.items.map((it) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(it.name)),
                  const SizedBox(width: 10),
                  Text(it.amount),
                ],
              ),
            );
          }),

          if (summary!.items.isNotEmpty) const Divider(height: 20),

          // TOTALS
          if (summary!.subtotal != null)
            _kv(context, 'Subtotal', summary!.subtotal!.amount),
          if (summary!.tax != null)
            _kv(context, summary!.tax!.label, summary!.tax!.amount),
          if (summary!.total != null)
            _kv(context, 'Total', summary!.total!.amount, isStrong: true),
        ],
      ),
    );
  }

  Widget _kv(
    BuildContext context,
    String k,
    String v, {
    bool isStrong = false,
  }) {
    final style = isStrong
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(k, style: style)),
          Text(v, style: style),
        ],
      ),
    );
  }
}
