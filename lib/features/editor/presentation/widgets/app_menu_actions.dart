import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import '../../../database_transfer/presentation/widgets/database_transfer_dialogs.dart';

class AppMenuActions {
  static Future<void> quit() => windowManager.close();

  static void changeWorkspace(BuildContext context) {
    context.go('/');
  }

  static Future<void> importDatabase(BuildContext context) =>
      showDatabaseImportFlow(context);

  static Future<void> exportDatabase(BuildContext context) =>
      showDatabaseExportFlow(context);
}
