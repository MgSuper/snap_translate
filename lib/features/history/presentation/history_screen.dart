import 'dart:io';

import 'package:camera_translator/app/router.dart';
import 'package:camera_translator/features/history/presentation/bloc/history_bloc.dart';
import 'package:camera_translator/features/history/presentation/bloc/history_event.dart';
import 'package:camera_translator/features/history/presentation/bloc/history_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            onPressed: () => _confirmClear(context),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          return switch (state) {
            HistoryLoading() => const _HistoryShimmer(),
            HistoryEmpty() => const _EmptyState(),
            HistoryFailure(:final message) => _ErrorState(message: message),
            HistoryLoaded(:final items) => ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.historyDetail, extra: item);
                  },
                  child: Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    onDismissed: (_) {
                      context.read<HistoryBloc>().add(
                        HistoryDeleteRequested(item.id),
                      );
                    },
                    child: Card(
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: File(item.renderedImagePath!).existsSync()
                                ? Image.file(
                                    File(item.renderedImagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          '${item.sourceLang.toUpperCase()} → ${item.targetLang.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item.createdAt.toLocal().toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () =>
                            context.push(AppRoutes.historyDetail, extra: item),
                      ),
                    ),
                  ),
                );
              },
            ),
          };
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This will delete all scan history records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      context.read<HistoryBloc>().add(const HistoryClearRequested());
    }
  }
}

class _HistoryShimmer extends StatelessWidget {
  const _HistoryShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      itemBuilder: (_, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Card(
              child: SizedBox(
                height: 72,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 14, width: double.infinity),
                      const SizedBox(height: 10),
                      SizedBox(height: 12, width: 180),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            const Text('No scans yet'),
            const SizedBox(height: 6),
            Text(
              'Scan a receipt and it will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
    );
  }
}
