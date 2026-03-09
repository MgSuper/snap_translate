import 'package:camera_translator/features/camera_translate/data/camera_scan_translator_service.dart';
import 'package:camera_translator/features/camera_translate/data/camera_translate_model_manager.dart';
import 'package:camera_translator/features/history/data/history_box.dart';
import 'package:camera_translator/features/history/data/scan_record.dart';
import 'package:camera_translator/features/history/repository/history_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

final getIt = GetIt.instance;

/// Step 1: register nothing heavy yet.
/// Step 2 onward: register repositories/services/blocs.
Future<void> configureDependencies() async {
  // Keep this async because later we’ll open Hive boxes, etc.
  // For now, nothing to register.
  // Hive init
  await Hive.initFlutter();

  // Register adapter once
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ScanRecordAdapter());
  }

  // Open boxes
  await Hive.openBox<ScanRecord>(HistoryBox.boxName);

  // Repos
  if (!getIt.isRegistered<HistoryRepository>()) {
    getIt.registerLazySingleton<HistoryRepository>(() => HistoryRepository());
  }

  getIt.registerLazySingleton<CameraScanTranslatorService>(
    () => MlKitCameraScanTranslatorService(),
  );

  getIt.registerLazySingleton<CameraTranslateModelManager>(
    () => MlKitCameraTranslateModelManager(),
  );
}
