import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1180, 760),
    minimumSize: Size(900, 600),
    center: true,
    title: 'Movie Tracker',
  );
  // Do not await before runApp: waitUntilReadyToShow waits for the first frame.
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setMinimumSize(const Size(900, 600));
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      child: const MovieTrackerApp(),
    ),
  );
}
