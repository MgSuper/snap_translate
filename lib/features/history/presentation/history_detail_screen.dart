import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera_translator/features/history/data/scan_record.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.record});

  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    final file = File(record.renderedImagePath!);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Capture')),
      body: file.existsSync()
          ? InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(child: Image.file(file)),
            )
          : Center(
              child: Text(
                'Image not found\n${record.renderedImagePath}',
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
