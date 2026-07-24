import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'app/database.dart';
import 'app/injection.dart';
import 'app/launch_bootstrap.dart';
import 'core/platform_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  final launchBootstrap = LaunchBootstrapConfig.fromEnvironment();
  await configureDependencies(launchBootstrap: launchBootstrap);
  final initialZoomLevel = await getIt<QueryPodDatabase>().loadZoomLevel();

  if (isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      center: true,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setResizable(true);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    App(
      initialLocation: launchBootstrap.initialLocation,
      initialZoomLevel: initialZoomLevel,
    ),
  );
}
