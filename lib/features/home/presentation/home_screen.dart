import 'package:camera_translator/app/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Translator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.scan),
              icon: const Icon(Icons.document_scanner),
              label: const Text('Scan Receipt'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.history),
              icon: const Icon(Icons.history),
              label: const Text('Scan History'),
            ),
            FilledButton(
              onPressed: () => context.push(AppRoutes.cameraTranslate),
              child: const Text('Camera Translate'),
            ),
            const Spacer(),
            Text(
              'Offline-first • OCR + on-device translation',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
