import 'package:camera_translator/app/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CameraTranslatorApp extends StatelessWidget {
  const CameraTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = AppRouter.router;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Camera Translator',
      routerConfig: router,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    );
  }
}
