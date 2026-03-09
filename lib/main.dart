import 'package:camera_translator/app/app.dart';
import 'package:camera_translator/app/core/di/di.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  runApp(const CameraTranslatorApp());
}
