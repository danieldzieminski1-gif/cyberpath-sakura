import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/content/data/content_repository.dart';
import 'features/live/data/live_repository.dart';
import 'features/progress/application/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) debugPrint('CyberPath error: ${details.exceptionAsString()}');
  };
  ErrorWidget.builder = (details) => Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Something went wrong on this screen. Go back and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
  final prefs = await SharedPreferences.getInstance();
  registerBonusContent(); // bundled 2026 course, works offline
  LiveRepository.applyCachedLessons(prefs); // lessons downloaded on earlier runs
  runApp(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs)],
    child: const CyberPathApp(),
  ));
}
