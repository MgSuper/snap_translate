import 'package:camera_translator/app/core/di/di.dart';
import 'package:camera_translator/features/camera_translate/presentation/camera_translate_screen.dart';
import 'package:camera_translator/features/history/data/scan_record.dart';
import 'package:camera_translator/features/history/presentation/bloc/history_bloc.dart';
import 'package:camera_translator/features/history/presentation/bloc/history_event.dart';
import 'package:camera_translator/features/history/presentation/history_detail_screen.dart';
import 'package:camera_translator/features/history/presentation/history_screen.dart';
import 'package:camera_translator/features/history/repository/history_repository.dart';
import 'package:camera_translator/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  static const home = '/';
  static const scan = '/scan';
  static const history = '/history';
  static const historyDetail = '/history/detail';
  static const cameraTranslate = '/camera-translate';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) =>
            const MaterialPage(child: HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.history,
        pageBuilder: (context, state) => MaterialPage(
          child: BlocProvider(
            create: (_) =>
                HistoryBloc(getIt<HistoryRepository>())
                  ..add(const HistoryLoadRequested()),
            child: const HistoryScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.historyDetail,
        pageBuilder: (context, state) {
          final record = state.extra! as ScanRecord;
          return MaterialPage(child: HistoryDetailScreen(record: record));
        },
      ),
      GoRoute(
        path: AppRoutes.cameraTranslate,
        pageBuilder: (context, state) =>
            const MaterialPage(child: CameraTranslateScreen()),
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation error')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          error?.toString() ?? 'Unknown routing error',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
